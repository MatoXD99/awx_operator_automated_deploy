# AWX Operator automated deploy
Automatically deploy AWX Operator on Ubuntu Server. Might work on other Linux distributions too. Tested on Ubuntu Server 24.04.01

## 1. Create "install_awx.sh" - the script is in GitHub
`nano install_awx.sh`

## 2. Make it executable
`chmod +x install_awx.sh`

## 3. Run it
`sudo ./install_awx.sh`

## 4. Open WebUI
`https://<your-server-ip>:37727/`

## 5. To retrieve the login password, execute this command
`kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode`

If something doesn't work, please open an issue and I'll look into it. Provide which system are you using, version and if it's a fresh install or already an existing one.
