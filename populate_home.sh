#!/bin/bash
# script to populate user home dirs. 
# January 17th, 2024

check_home_dir(){
    user="$1"
    home_dir="/sciclone/home/$user"
    if [[ ! -d "$home_dir" ]]; then
        echo "/sciclone/home/$user does not exist, creating..."
        make_home_dir $user
    fi
}

make_home_dir(){
    user="$1"
    group=$(groups "$user" | awk -F " " '{print $3}')
    wmuserid=$(cat /etc/passwd | grep @ | grep -i "$user" | awk -F ':' '{print $1 "--" $5}'| awk -F "--" '{print $4}')
    #echo $user
    mkdir -v /sciclone/home/$user
    echo "home dir created, copying env files"
    cd /sciclone/home/$user
    for i in .bash_profile .bashrc .bashrc.astral .bashrc.bora .bashrc.femto .bashrc.gulf .bashrc.gust .bashrc.kuro .bashrc.viz .cshrc .cshrc.astral .cshrc.bora .cshrc.femto .cshrc.gulf .cshrc.gust .cshrc.kuro .cshrc.viz .forward .k5login .login
    do # for each env file, copy it over, adjust permissions
        # for .k5login and .forward, should be owned by root:root
        cp -v /etc/skel/$i /sciclone/home/$user/$i
        echo "/sciclone/home/$user/$i created.";
        chmod -v 644 /sciclone/home/$user/$i
        if [[ "$i" == ".forward" || "$i" == ".k5login" ]]; then
            chown -v root:root /sciclone/home/$user/$i
        else
            chown -v $user:root /sciclone/home/$user/$i
        fi
    done
    # set permissions for sciclone home dir, this is correct
    chown -v $user:$group /sciclone/home/$user
    chmod -v 700 /sciclone/home/$user
    su - $user -c "/usr/local/bin/restorewmlinks" # create symlinks for user using ejw's script
    # replace wmuserid with $user in .k5login and username@wm.edu with email in .forward

    sed -i "s/wmuserid/$wmuserid/g" /sciclone/home/$user/.k5login
    # if the .forward file is empty, add the email to it.
    email=$(cat /etc/passwd | grep @ | awk -F ':' '{print $1 "--" $5}' | awk -F '--' '{print $1 " "  $3 ""}' | sort | grep -i "^$user\b" | awk -F " " '{print $2}')
    echo $email >> /sciclone/home/$user/.forward
    echo "Creation of $user .forward done."
    echo "--------------------------------"
}

# main
# if the user's uid > 1000, they are not expired, and home dir does not exist,
# then create it.
users=$(grep -i /sciclone/home /etc/passwd | awk -F":" '{print $1}' | sort)
for user in $users
do
    expiry=$(chage -l "$user" | grep -i "Account expires" | awk -F ": " '{print $2}')
    if [[ ! $expiry = "never" ]]; then # if the expire is not never, then check to see if they are expired
        epoch_date=$(date -d "$expiry" +%s)
        uid=$(id -u "$user")
        if [[ "$uid" -gt 1000 ]] && [[ "$epoch_date" -gt "$(date +%s)" ]]; then
            check_home_dir $user
        fi
    else # if their expiry is never, then you can just create the home dir
        check_home_dir $user
    fi
done;
printf "Done checking directory list."
