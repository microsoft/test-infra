# Setup a new Jenkins master server

1. Create a new resource group via the `az cli`:
    ```
    az group create \
        --output table \
        --name OE-Prow-Testing \
        --location uksouth
    ```

2. Create the Jenkins master VM

    ```
    az vm create \
        --output table \
        --resource-group OE-Prow-Testing \
        --location uksouth \
        --name jenkins-master-testing \
        --size Standard_DS3_v2 \
        --os-disk-size-gb 128 \
        --data-disk-sizes-gb 512 \
        --image Canonical:UbuntuServer:18_04-lts-gen2:latest \
        --accelerated-networking true \
        --nsg-rule SSH \
        --admin-username oeadmin \
        --ssh-key-value ~/.ssh/id_rsa.pub
    ```
    If you want to attach the new Jenkins master to an existing VNET, add the following parameter:
    ```
    --subnet <AZURE_SUBNET_ID>
    ```
    For example giving:
    ```
    --subnet /subscriptions/c4fdda6e-bfbd-4b8e-9703-037b3a45bf37/resourceGroups/OE-Jenkins-terraform/providers/Microsoft.Network/virtualNetworks/OE-Jenkins-terraform-test/subnets/subnet1
    ```
    attaches the VM to the `subnet1` subnet from the `OE-Jenkins-terraform-test` VNET from the `OE-Jenkins-terraform` resource group.

3. Make sure the new existing VM allows port `443` (used for the HTTPS Jenkins web UI) and port `80` (redirects to `443`).

    The port `80` needs to be open to complete the [http-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) when generating / renewing the SSL certificate.

    The following commands open ports `443` / `80`:
    ```
    NIC_ID=`az vm show --resource-group OE-Prow-Testing \
                       --name jenkins-master-testing \
                       --output tsv \
                       --query "networkProfile.networkInterfaces[0].id"`

    NSG_ID=`az network nic show --ids $NIC_ID \
                                --output tsv \
                                --query "networkSecurityGroup.id"`

    NSG_NAME=`az network nsg show --ids $NSG_ID \
                                  --output tsv \
                                  --query "name"`

    az network nsg rule create --resource-group OE-Prow-Testing \
                               --nsg-name $NSG_NAME \
                               --name Port_443 \
                               --priority 500 \
                               --access Allow \
                               --direction Inbound \
                               --protocol Tcp \
                               --destination-port-ranges 443

    az network nsg rule create --resource-group OE-Prow-Testing \
                               --nsg-name $NSG_NAME \
                               --name Port_80 \
                               --priority 501 \
                               --access Allow \
                               --direction Inbound \
                               --protocol Tcp \
                               --destination-port-ranges 80
    ```
    **NOTE**: Keep in mind that the virtual machine VNET might have a security group applied. You need to open port `80` / `443` for that as well.

4. Attach a DNS to the machine public address:
    ```
    NIC_ID=`az vm show --resource-group OE-Prow-Testing \
                       --name jenkins-master-testing \
                       --output tsv \
                       --query "networkProfile.networkInterfaces[0].id"`

    PUBLIC_IP_ID=`az network nic show --ids $NIC_ID \
                                      --output tsv \
                                      --query "ipConfigurations[0].publicIpAddress.id"`

    az network public-ip update --ids $PUBLIC_IP_ID \
                                --dns-name oe-prow-testing \
                                --idle-timeout 30
    ```
    The above will set the `oe-prow-testing.uksouth.cloudapp.azure.com` as the public DNS name for the VM.

5. SSH into the machine
    ```
    ssh oeadmin@oe-prow-testing.uksouth.cloudapp.azure.com
    ```

6. (Optional) Identify the extra data disk attached to the VM by running `sudo fdisk -l` command:
    ```
    oeadmin@jenkins-master-testing:~/openenclave-infra-config$ sudo fdisk -l
    Disk /dev/sda: 512 GiB, 549755813888 bytes, 1073741824 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 4096 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes


    Disk /dev/sdb: 128 GiB, 137438953472 bytes, 268435456 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 4096 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes
    Disklabel type: gpt
    Disk identifier: 1063137B-3864-48EE-946E-22FB0FA6320A

    Device      Start       End   Sectors   Size Type
    /dev/sdb1  227328 268435422 268208095 127.9G Linux filesystem
    /dev/sdb14   2048     10239      8192     4M BIOS boot
    /dev/sdb15  10240    227327    217088   106M EFI System

    Partition table entries are not in disk order.


    Disk /dev/sdc: 28 GiB, 30064771072 bytes, 58720256 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 4096 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes
    Disklabel type: dos
    Disk identifier: 0x8c7a2f13

    Device     Boot Start      End  Sectors Size Id Type
    /dev/sdc1         128 58718207 58718080  28G  7 HPFS/NTFS/exFAT
    ```

    From the output above, we may notice that the `/dev/sda` disk doesn't have any partition table and it has a capacity of `512 GB`. Therefore, this is the extra data disk we attached to the VM.

    We are going to use this disk to store all the Jenkins master data.

7. (Optional) Setup the identified extra disk:

    * Create the partition table. This will create a single partition with all the disk space at `/dev/sda1`:
        ```
        (echo n; echo p; echo; echo; echo; echo w) | sudo fdisk /dev/sda
        ```

    * Format the data disk partition:
        ```
        sudo mkfs.ext4 /dev/sda1
        ```

    * Create `/var/jenkins_home` (this will be used as a mount point):
        ```
        sudo mkdir /var/jenkins_home
        ```

    * Add entry to `/etc/fstab`:
        ```
        UUID=`sudo blkid -s UUID -o value /dev/sda1`
        FSTAB_ENTRY="UUID=${UUID}  /var/jenkins_home  ext4  defaults  0 0"
        if ! sudo grep -q "$FSTAB_ENTRY" /etc/fstab; then
            sudo sed -ie "\$a${FSTAB_ENTRY}" /etc/fstab
        fi
        ```

    * Mount the partitions from `/etc/fstab`:
        ```
        sudo mount -a
        ```

    * At this point, the `df -h` command should list the partition mounted to `/var/jenkins_home`:
        ```
        Filesystem      Size  Used Avail Use% Mounted on
        udev            6.8G     0  6.8G   0% /dev
        tmpfs           1.4G  628K  1.4G   1% /run
        /dev/sdb1       124G  2.1G  122G   2% /
        tmpfs           6.9G     0  6.9G   0% /dev/shm
        tmpfs           5.0M     0  5.0M   0% /run/lock
        tmpfs           6.9G     0  6.9G   0% /sys/fs/cgroup
        /dev/sdb15      105M  3.6M  101M   4% /boot/efi
        /dev/sdc1        28G   45M   26G   1% /mnt
        tmpfs           1.4G     0  1.4G   0% /run/user/998
        tmpfs           1.4G     0  1.4G   0% /run/user/1000
        /dev/sda1       503G   73M  478G   1% /var/jenkins_home
        ```
        And it should be mounted automatically at boot time.


8. Clone the openenclave-infra-config repository and `cd` to it:
    ```
    git clone https://github.com/openenclave-ci/test-infra
    cd test-infra/config/jenkins/master
    ```

9. Run the Jenkins master setup script under `root` user:
    ```
    sudo su
    export JENKINS_PUBLIC_DNS_ADDRESS=oe-prow-testing.uksouth.cloudapp.azure.com
    ./setup.sh
    ```
    The setup script does the following:
    * Docker installation
    * NGinx installation (used as the HTTPs proxy for the Jenkins master)
    * Letsencrypt SSL certificates configuration (done via certbot)
    * Jenkins master systemd configuration
    * HTTPs proxy for Jenkins master via NGinx configuration

10. (experimatental) Install the saved `plugins.txt` for Jenkins master:
    ```
    sudo ./install-plugins.sh
    ```
    **NOTE**: Keep in mind that it will restart Jenkins master at the end


11. Unlock Jenkins, in your browser go to: https://oe-prow-testing.uksouth.cloudapp.azure.com/

In your terminal grab the password from
```
sudo cat /var/jenkins_home/secrets/initialAdminPassword
```

12. Install Plugins We Care about

```
Azure Virtual Machine Scale Set
```