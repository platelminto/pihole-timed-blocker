# pihole-timed-blacklist
A project to deploy a Pi-hole instance, with a cron-based system for blocking specific domains during set hours. Set the Pi as your Tailscale network's DNS resolver and this'll work automatically, across devices, across networks. See the end of this guide for more on that.

I made this to spend less time on social media. I already bought a phone where accessing them is a hassle, but I noticed my usage on my other devices increased. This aims to change that! It also would work on a smartphone if you do have one, since it's DNS.

## Why this instead of X?
* **Why not use most routers' existing domain blacklist functionality?** Most have time-based blocking, but not all. Also, not a solution for when you leave your home network.
* **Why not use a browser extension?** This blocks your phone apps too! Also, it does not take a lot of clicks to disable an extension. Or use a different browser. I know, it's easy to disable Pi-hole too, but I think the friction is slightly higher - plus, you're disabling your Pi-hole! Many extensions also sell your data to advertisers, or eventually do. I wanted to avoid that.

But really, my thesis deadline is fast approaching, so I worked on this all day rather than go to the library.

## Prerequisites
*   A host machine (e.g., Raspberry Pi) with SSH access.
*   [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

    Though not necessary by any means, I used Docker for this. You don't have to! Most of this will work just as easily, if not more.

    *   [Docker](https://docs.docker.com/engine/install/)
    *   [Docker Compose](https://docs.docker.com/compose/install/)

## Step 1: Getting Started
#### A. Clone the Repository
Clone this repository onto your host machine.
```
git clone https://github.com/platelminto/pihole-timed-blacklist.git
cd pihole-timed-blacklist
```
#### B. Set File Permissions
After cloning, you must make the scripts executable.
```
sudo chmod +x ./scripts/*.sh
```
## Step 2: Configuration
Before deploying, customize the configuration to your needs.

1.  **Edit the Domain List:** Open `timed_domains.list` and add or remove the domains you wish to block.
    ```
    nano timed_domains.list
    ```
2.  **Set Your Password:** Open `docker-compose.yml` and change the `WEBPASSWORD` environment variable to a strong, unique password.
    ```
    nano docker-compose.yml
    ```
## Step 3: Deployment (Choose One Method)
### Method 1: Using Command Line (Recommended)
This method works directly with the `docker-compose.yml` file in this repository.
1.  Navigate to the project directory:
    ```
    cd ~/pihole-timed-blacklist/
    ```
2.  Deploy the stack:
    ```
    sudo docker-compose up -d
    ```
---
### Method 2: Using Portainer (Alternative)
When using Portainer's web editor to create a stack, you **must use absolute paths** for volumes, as it does not have the context of the project directory.
1.  **Install Portainer** if needed:
    ```
    sudo docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v ~/appdata/portainer:/data portainer/portainer-ce:latest
    ```
    Open `http://<your_pi_ip_address>:9000` and create your admin user.
2.  In the Portainer UI, go to **Stacks** > **+ Add stack**.
3.  Give the stack a name, e.g., `pihole-stack`.
4.  In the **Web editor**, paste the `docker-compose.yml` content, but with the **`volumes` section modified to use full, absolute paths**. See the example below.
5.  Click **Deploy the stack**.

**Example of Modified Content for Portainer Web Editor:**
(Replace `/home/platelminto` with the absolute path to your user's home directory)
```yaml
version: "3"

services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
      - "80:80/tcp"
    environment:
      TZ: 'Europe/Amsterdam'
      # Set your web password directly here. Use a strong one!
      WEBPASSWORD: 'CHANGE_THIS_PASSWORD'
    volumes:
      - '/home/platelminto/appdata/pihole-timed-blacklist/etc-pihole:/etc/pihole'
      - '/home/platelminto/appdata/pihole-timed-blacklist/etc-dnsmasq.d:/etc/dnsmasq.d'
      - '/home/platelminto/appdata/pihole-timed-blacklist/scripts:/usr/local/bin/custom_scripts'
      - '/home/platelminto/appdata/pihole-timed-blacklist/timed_domains.list:/etc/pihole/timed_domains.list'
    cap_add:
      - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
    restart: unless-stopped
```
## Step 4: Making Your Devices Use Pi-hole (Crucial Step)
Your Pi-hole is running, but you must configure your devices to use it as their DNS server. The recommended and most flexible method is with **Tailscale**, which allows your devices to use Pi-hole securely from anywhere.

**Follow the official guide here: [Using Pi-hole with Tailscale](https://tailscale.com/kb/1114/pi-hole)**

_(Alternatively, for local network use only, you could manually change the DNS settings on each device to point to your Raspberry Pi's local IP address.)_

## Step 5: Verification and Automation
Before setting up the automated schedule, it's a good idea to test that the scripts work correctly.

#### A. Verify Manual Control (Recommended)
**1. Test the Block Script:**
Run the block command from your host machine's terminal:
```
sudo docker exec pihole /usr/local/bin/custom_scripts/block_sites.sh
```
To check if it worked, you can use the `dig` command, pointing it directly at your Pi-hole's Tailscale IP address. The response should be `0.0.0.0`.
```
# Replace <your_pi_ip> with your Raspberry Pi's Tailscale IP address
dig youtube.com @<your_pi_ip>
```
Alternatively, check the "Domains" page in your Pi-hole web UI. You should see the domains listed as "Wildcard blocking".

**2. Test the Unblock Script:**
Next, run the unblock command:
```
sudo docker exec pihole /usr/local/bin/custom_scripts/unblock_sites.sh
```
Check again using the same method. The `dig` command should now return the real IP address for the domain, and the entries will be gone from the "Domains" page in the web UI.

#### B. Set Up the Timed Automation (Cron Job)
Once you've confirmed the scripts work, set up the schedule.
1.  Open the root user's crontab for editing:
    ```
    sudo crontab -e
    ```
2.  Add the following lines. This example blocks sites every day at 2:00 AM and unblocks them at 10:00 PM (22:00).
    _(Note: The command inside the crontab does not need_ `sudo` _because the job is already being run by the root user.)_
    ```cron
    0 2 * * * docker exec pihole /usr/local/bin/custom_scripts/block_sites.sh
    0 22 * * * docker exec pihole /usr/local/bin/custom_scripts/unblock_sites.sh
    ```
3.  Save the file and exit.

## Step 6: Maintenance
*   **To change which domains are blocked:** Edit the `timed_domains.list` file in the project directory.
*   **To change the block/unblock times:** Edit the schedule by running `sudo crontab -e`.


## Planned features
* [ ] Easier separate times per domain
