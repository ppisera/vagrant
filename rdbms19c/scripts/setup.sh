echo "******************************************************************************"
echo " prepare disks"
echo "******************************************************************************"
sudo bash -c 'sh /vagrant/scripts/prepare_disks.sh'

echo "******************************************************************************"
echo " do some preinstall things - install necessary packages"
echo "******************************************************************************"
sudo bash -c 'sh /vagrant/scripts/ora_pre_install.sh'

echo "******************************************************************************"
echo " install RDBMS"
echo "******************************************************************************"
sudo su - oracle -c 'sh /vagrant/scripts/ora_install.sh'
sudo bash -c 'sh /vagrant/scripts/ora_post_install.sh'

echo "******************************************************************************"
echo "Create the database :" `date`
echo "******************************************************************************"
su - oracle -c 'sh /vagrant/scripts/oracle_create_database.sh'

echo "******************************************************************************"
echo "Finished :" `date`
echo "******************************************************************************"
