import json
import boto3
import datetime
import os
import time
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to backup OpenVPN Access Server configuration
    """
    
    # Environment variables
    backup_bucket = os.environ['BACKUP_BUCKET']
    instance_ids = json.loads(os.environ['INSTANCE_IDS'])
    name_prefix = os.environ['NAME_PREFIX']
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN', '')
    retention_days = int(os.environ.get('RETENTION_DAYS', '30'))
    
    # AWS clients
    ssm_client = boto3.client('ssm')
    s3_client = boto3.client('s3')
    sns_client = boto3.client('sns')
    ec2_client = boto3.client('ec2')
    
    print(f"Starting backup process for instances: {instance_ids}")
    
    backup_results = []
    
    for instance_id in instance_ids:
        try:
            # Check if instance is running
            response = ec2_client.describe_instances(InstanceIds=[instance_id])
            instance_state = response['Reservations'][0]['Instances'][0]['State']['Name']
            
            if instance_state != 'running':
                print(f"Instance {instance_id} is not running (state: {instance_state}), skipping backup")
                backup_results.append({
                    'instance_id': instance_id,
                    'status': 'skipped',
                    'reason': f'Instance not running (state: {instance_state})'
                })
                continue
            
            # Create backup timestamp
            timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_filename = f"openvpn_backup_{instance_id}_{timestamp}.tar.gz"
            
            # Backup commands
            backup_commands = [
                '#!/bin/bash',
                'set -e',
                f'BACKUP_FILE="/tmp/{backup_filename}"',
                'BACKUP_DIR="/tmp/openvpn_backup_$(date +%Y%m%d_%H%M%S)"',
                'mkdir -p $BACKUP_DIR',
                '',
                '# Backup OpenVPN configuration',
                '/usr/local/openvpn_as/scripts/sacli --output_format=json ConfigBackup > $BACKUP_DIR/config_backup.json',
                '',
                '# Backup user database',
                'cp /usr/local/openvpn_as/etc/db/userprop.db $BACKUP_DIR/ 2>/dev/null || echo "User database not found"',
                'cp /usr/local/openvpn_as/etc/db/log.db $BACKUP_DIR/ 2>/dev/null || echo "Log database not found"',
                '',
                '# Backup SSL certificates',
                'mkdir -p $BACKUP_DIR/ssl',
                'cp -r /usr/local/openvpn_as/etc/web-ssl/* $BACKUP_DIR/ssl/ 2>/dev/null || echo "SSL certificates not found"',
                '',
                '# Backup Let\'s Encrypt certificates if they exist',
                'if [ -d "/etc/letsencrypt/live" ]; then',
                '    mkdir -p $BACKUP_DIR/letsencrypt',
                '    cp -r /etc/letsencrypt/live/* $BACKUP_DIR/letsencrypt/ 2>/dev/null || echo "Let\'s Encrypt certificates not found"',
                'fi',
                '',
                '# Create system info',
                'echo "Backup created on: $(date)" > $BACKUP_DIR/backup_info.txt',
                'echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> $BACKUP_DIR/backup_info.txt',
                'echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> $BACKUP_DIR/backup_info.txt',
                'echo "OpenVPN Version: $(/usr/local/openvpn_as/scripts/sacli --version)" >> $BACKUP_DIR/backup_info.txt',
                '',
                '# Create compressed archive',
                'cd /tmp',
                'tar -czf "$BACKUP_FILE" "$(basename $BACKUP_DIR)"',
                '',
                '# Upload to S3 using AWS CLI',
                f'aws s3 cp "$BACKUP_FILE" "s3://{backup_bucket}/backups/{backup_filename}"',
                '',
                '# Clean up local files',
                'rm -rf "$BACKUP_FILE" "$BACKUP_DIR"',
                '',
                'echo "Backup completed successfully: {backup_filename}"'
            ]
            
            # Execute backup command via SSM
            command_script = '\n'.join(backup_commands)
            
            response = ssm_client.send_command(
                InstanceIds=[instance_id],
                DocumentName="AWS-RunShellScript",
                Parameters={
                    'commands': [command_script]
                },
                Comment=f"OpenVPN backup for {instance_id}",
                TimeoutSeconds=1800  # 30 minutes
            )
            
            command_id = response['Command']['CommandId']
            print(f"Backup command sent to {instance_id}, command ID: {command_id}")
            
            # Wait for command completion
            max_wait_time = 1800  # 30 minutes
            wait_time = 0
            sleep_interval = 30
            
            while wait_time < max_wait_time:
                time.sleep(sleep_interval)
                wait_time += sleep_interval
                
                try:
                    invocation = ssm_client.get_command_invocation(
                        CommandId=command_id,
                        InstanceId=instance_id
                    )
                    
                    status = invocation['Status']
                    
                    if status in ['Success', 'Failed', 'Cancelled', 'TimedOut']:
                        break
                        
                except ClientError as e:
                    if e.response['Error']['Code'] == 'InvocationDoesNotExist':
                        continue
                    else:
                        raise
            
            # Check final status
            if status == 'Success':
                print(f"Backup completed successfully for {instance_id}")
                backup_results.append({
                    'instance_id': instance_id,
                    'status': 'success',
                    'backup_file': backup_filename,
                    'timestamp': timestamp
                })
            else:
                print(f"Backup failed for {instance_id}: {status}")
                stdout = invocation.get('StandardOutputContent', '')
                stderr = invocation.get('StandardErrorContent', '')
                backup_results.append({
                    'instance_id': instance_id,
                    'status': 'failed',
                    'error': f"Command status: {status}",
                    'stdout': stdout[-1000:] if stdout else '',  # Last 1000 chars
                    'stderr': stderr[-1000:] if stderr else ''   # Last 1000 chars
                })
            
        except Exception as e:
            print(f"Error backing up instance {instance_id}: {str(e)}")
            backup_results.append({
                'instance_id': instance_id,
                'status': 'error',
                'error': str(e)
            })
    
    # Clean up old backups
    try:
        cleanup_old_backups(s3_client, backup_bucket, retention_days)
    except Exception as e:
        print(f"Error cleaning up old backups: {str(e)}")
    
    # Send notification if SNS topic is configured
    if sns_topic_arn:
        try:
            send_notification(sns_client, sns_topic_arn, backup_results, name_prefix)
        except Exception as e:
            print(f"Error sending notification: {str(e)}")
    
    # Store backup status in SSM Parameter
    try:
        ssm_client.put_parameter(
            Name=f'/{name_prefix}/openvpn/last_backup_status',
            Value=json.dumps({
                'timestamp': datetime.datetime.now().isoformat(),
                'results': backup_results
            }),
            Type='String',
            Overwrite=True
        )
    except Exception as e:
        print(f"Error storing backup status: {str(e)}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Backup process completed',
            'results': backup_results
        })
    }

def cleanup_old_backups(s3_client, bucket_name, retention_days):
    """
    Remove backups older than retention_days
    """
    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=retention_days)
    
    try:
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix='backups/'
        )
        
        if 'Contents' not in response:
            print("No backup files found for cleanup")
            return
        
        deleted_count = 0
        for obj in response['Contents']:
            if obj['LastModified'].replace(tzinfo=None) < cutoff_date:
                s3_client.delete_object(
                    Bucket=bucket_name,
                    Key=obj['Key']
                )
                print(f"Deleted old backup: {obj['Key']}")
                deleted_count += 1
        
        print(f"Cleaned up {deleted_count} old backup files")
        
    except Exception as e:
        print(f"Error during cleanup: {str(e)}")
        raise

def send_notification(sns_client, topic_arn, backup_results, name_prefix):
    """
    Send backup status notification via SNS
    """
    successful_backups = [r for r in backup_results if r['status'] == 'success']
    failed_backups = [r for r in backup_results if r['status'] in ['failed', 'error']]
    skipped_backups = [r for r in backup_results if r['status'] == 'skipped']
    
    subject = f"OpenVPN Backup Report - {name_prefix}"
    
    if failed_backups:
        subject += " - FAILURES DETECTED"
    
    message_lines = [
        f"OpenVPN Backup Report for {name_prefix}",
        f"Execution Time: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}",
        "",
        f"Summary:",
        f"- Successful: {len(successful_backups)}",
        f"- Failed: {len(failed_backups)}",
        f"- Skipped: {len(skipped_backups)}",
        ""
    ]
    
    if successful_backups:
        message_lines.append("Successful Backups:")
        for backup in successful_backups:
            message_lines.append(f"- Instance {backup['instance_id']}: {backup.get('backup_file', 'N/A')}")
        message_lines.append("")
    
    if failed_backups:
        message_lines.append("Failed Backups:")
        for backup in failed_backups:
            message_lines.append(f"- Instance {backup['instance_id']}: {backup.get('error', 'Unknown error')}")
        message_lines.append("")
    
    if skipped_backups:
        message_lines.append("Skipped Backups:")
        for backup in skipped_backups:
            message_lines.append(f"- Instance {backup['instance_id']}: {backup.get('reason', 'Unknown reason')}")
        message_lines.append("")
    
    message_lines.extend([
        "This is an automated message from the OpenVPN backup system.",
        "Please check the AWS Lambda logs for detailed information."
    ])
    
    message = '\n'.join(message_lines)
    
    sns_client.publish(
        TopicArn=topic_arn,
        Subject=subject,
        Message=message
    )
    
    print(f"Notification sent to {topic_arn}")