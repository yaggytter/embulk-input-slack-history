# embulk-input-slack-history

This [Embulk](https://github.com/embulk/embulk) input plugin for Slack chat history.


## Installation

		$ java -jar embulk.jar gem install embulk-input-slack-history

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
out:
  type: stdout
```

## TODO

- attachment file download
- do not update *.oldest file at preview time
- error handling and resume
- multi thread execute Slack API if needed
