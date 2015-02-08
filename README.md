# embulk-plugin-input-slack-history

This [Embulk](https://github.com/embulk/embulk) input plugin for Slack chat history.

## Configuration

- **token** Slack API token 'Generate from https://api.slack.com/' (string, required)
- **continuous** last time read continuation (string, default: false)
- **filepath** continuous information file save path (string, default: /tmp)

### Example

```yaml
in:
  type: slack_history
  token: slackapitoken
  continuous: true # optional
  filepath: /tmp # optional
  columns:
    - { name: channelid, type: string }
    - { name: channelname, type: string }
    - { name: private, type: string }
    - { name: datetime, type: timestamp }
    - { name: username, type: string }
    - { name: userid, type: string }
    - { name: message, type: string }
out:
  type: stdout
```
