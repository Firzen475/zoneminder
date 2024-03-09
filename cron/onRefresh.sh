#/bin/sh /etc/init.d/start.sh
curl -XPOST -k -d "user=[OBSERVER1]&pass=[OBSERVER_PASSWORD1]" https://localhost/zm/api/host/login.json | jq -r '.access_token' > /observer1
curl -XPOST -k -d "user=[OBSERVER2]&pass=[OBSERVER_PASSWORD2]" https://localhost/zm/api/host/login.json | jq -r '.access_token' > /observer2
