Review and disable any unnecessary scheduled tasks.

To get a list of all scheduled tasks, open the Terminal as an Administrator and run the following command:

C:\> Get-ScheduledTask

Use the command below to search for tasks that have the word 'schedule' in their name.

C:\> Get-ScheduledTask -TaskName '*schedule*'

TaskPath                                TaskName                         State
--------                                --------                         -----
\Microsoft\Windows\Defrag\              ScheduledDefrag                  Ready
\Microsoft\Windows\Diagnosis\           Scheduled                        Ready
\Microsoft\Windows\UpdateOrchestrator\  Schedule Maintenance Work        Disabled
\Microsoft\Windows\UpdateOrchestrator\  Schedule Scan                    Ready
\Microsoft\Windows\UpdateOrchestrator\  Schedule Scan Static Task        Ready
\Microsoft\Windows\UpdateOrchestrator\  Schedule Wake To Work            Disabled
\Microsoft\Windows\UpdateOrchestrator\  Schedule Work                    Ready
\Microsoft\Windows\Windows Defender\    Windows Defender Scheduled Scan  Ready
\Microsoft\Windows\WindowsUpdate\       Scheduled Start                  Ready

I'm only going to disable the ScheduledDefrag task. It is entirely up to you which other scheduled tasks you wish to disable.

C:\> Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName ScheduledDefrag

TaskPath                    TaskName         State
--------                    --------         -----
\Microsoft\Windows\Defrag\  ScheduledDefrag  Disabled