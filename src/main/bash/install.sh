#!/bin/bash
#
#   Copyright 2012 Marco Vermeulen
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Global variables
GVM_SERVICE="@GVM_SERVICE@"
GVM_VERSION="@GVM_VERSION@"
GVM_DIR="$HOME/.gvm"

# Local variables
gvm_bin_folder="${GVM_DIR}/bin"
gvm_src_folder="${GVM_DIR}/src"
gvm_tmp_folder="${GVM_DIR}/tmp"
gvm_stage_folder="${gvm_tmp_folder}/stage"
gvm_zip_file="${gvm_tmp_folder}/res-${GVM_VERSION}.zip"
gvm_ext_folder="${GVM_DIR}/ext"
gvm_etc_folder="${GVM_DIR}/etc"
gvm_config_file="${gvm_etc_folder}/config"
gvm_bash_profile="${HOME}/.bash_profile"
gvm_profile="${HOME}/.profile"
gvm_bashrc="${HOME}/.bashrc"
gvm_zshrc="${HOME}/.zshrc"
gvm_platform=$(uname)

gvm_init_snippet=$( cat << EOF
#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "${GVM_DIR}/bin/gvm-init.sh" ]] && source "${GVM_DIR}/bin/gvm-init.sh"
EOF
)

# OS specific support (must be 'true' or 'false').
cygwin=false;
darwin=false;
solaris=false;
freebsd=false;
case "$(uname)" in
    CYGWIN*)
        cygwin=true
        ;;
    Darwin*)
        darwin=true
        ;;
    SunOS*)
        solaris=true
        ;;
    FreeBSD*)
        freebsd=true
esac

echo '                                                                     '
echo 'Thanks for using                                                     '
echo '                                                                     '
echo '_____/\\\\\\\\\\\\__/\\\________/\\\__/\\\\____________/\\\\_        '
echo ' ___/\\\//////////__\/\\\_______\/\\\_\/\\\\\\________/\\\\\\_       '
echo '  __/\\\_____________\//\\\______/\\\__\/\\\//\\\____/\\\//\\\_      '
echo '   _\/\\\____/\\\\\\\__\//\\\____/\\\___\/\\\\///\\\/\\\/_\/\\\_     '
echo '    _\/\\\___\/////\\\___\//\\\__/\\\____\/\\\__\///\\\/___\/\\\_    '
echo '     _\/\\\_______\/\\\____\//\\\/\\\_____\/\\\____\///_____\/\\\_   '
echo '      _\/\\\_______\/\\\_____\//\\\\\______\/\\\_____________\/\\\_  '
echo '       _\//\\\\\\\\\\\\/_______\//\\\_______\/\\\_____________\/\\\_ '
echo '        __\////////////__________\///________\///______________\///__'
echo '                                                                     '
echo '                                       Will now attempt installing...'
echo '                                                                     '


# Sanity checks

echo "Looking for a previous installation of GVM..."
if [ -d "${GVM_DIR}" ]; then
	echo "GVM found."
	echo ""
	echo "======================================================================================================"
	echo " You already have GVM installed."
	echo " GVM was found at:"
	echo ""
	echo "    ${GVM_DIR}"
	echo ""
	echo " Please consider running the following if you need to upgrade."
	echo ""
	echo "    $ gvm selfupdate"
	echo ""
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for unzip..."
if [ -z $(which unzip) ]; then
	echo "Not found."
	echo "======================================================================================================"
	echo " Please install unzip on your system using your favourite package manager."
	echo ""
	echo " Restart after installing unzip."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for curl..."
if [ -z $(which curl) ]; then
	echo "Not found."
	echo ""
	echo "======================================================================================================"
	echo " Please install curl on your system using your favourite package manager."
	echo ""
	echo " GVM uses curl for crucial interactions with it's backend server."
	echo ""
	echo " Restart after installing curl."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for sed..."
if [ -z $(which sed) ]; then
	echo "Not found."
	echo ""
	echo "======================================================================================================"
	echo " Please install sed on your system using your favourite package manager."
	echo ""
	echo " GVM uses sed extensively."
	echo ""
	echo " Restart after installing sed."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

if [[ "${solaris}" == true ]]; then
	echo "Looking for gsed..."
	if [ -z $(which gsed) ]; then
		echo "Not found."
		echo ""
		echo "======================================================================================================"
		echo " Please install gsed on your solaris system."
		echo ""
		echo " GVM uses gsed extensively."
		echo ""
		echo " Restart after installing gsed."
		echo "======================================================================================================"
		echo ""
		exit 0
	fi
fi


echo "Installing gvm scripts..."


# Create directory structure

echo "Create distribution directories..."
mkdir -p "${gvm_bin_folder}"
mkdir -p "${gvm_src_folder}"
mkdir -p "${gvm_tmp_folder}"
mkdir -p "${gvm_stage_folder}"
mkdir -p "${gvm_ext_folder}"
mkdir -p "${gvm_etc_folder}"

echo "Create candidate directories..."
mkdir -p "${GVM_DIR}/groovy"
mkdir -p "${GVM_DIR}/grails"
mkdir -p "${GVM_DIR}/griffon"
mkdir -p "${GVM_DIR}/gradle"
mkdir -p "${GVM_DIR}/lazybones"
mkdir -p "${GVM_DIR}/vertx"

echo "Prime the config file..."
touch "${gvm_config_file}"
echo "gvm_auto_answer=false" >> "${gvm_config_file}"

echo "Download script archive..."
curl -s "${GVM_SERVICE}/res?platform=${gvm_platform}&purpose=install" > "${gvm_zip_file}"

echo "Extract script archive..."
if [[ "${cygwin}" == 'true' ]]; then
	echo "Cygwin detected - normalizing paths for unzip..."
	unzip -qo $(cygpath -w "${gvm_zip_file}") -d $(cygpath -w "${gvm_stage_folder}")	
else
	unzip -qo "${gvm_zip_file}" -d "${gvm_stage_folder}"
fi

echo "Install scripts..."
mv "${gvm_stage_folder}/gvm-init.sh" "${gvm_bin_folder}"
mv "${gvm_stage_folder}/gvm-include.sh" "${gvm_bin_folder}"
mv "${gvm_stage_folder}"/gvm-* "${gvm_src_folder}"

echo "Make init script executable..."
chmod -R +x "${gvm_bin_folder}"

echo "Attempt update of bash profiles..."
if [ ! -f "${gvm_bash_profile}" -a ! -f "${gvm_profile}" ]; then
	echo "#!/bin/bash" > "${gvm_bash_profile}"
	echo "${gvm_init_snippet}" >> "${gvm_bash_profile}"
	echo "Created and initialised ${gvm_bash_profile}"
else
	if [ -f "${gvm_bash_profile}" ]; then
		if [[ -z `grep 'gvm-init.sh' "${gvm_bash_profile}"` ]]; then
			echo -e "\n${gvm_init_snippet}" >> "${gvm_bash_profile}"
			echo "Updated existing ${gvm_bash_profile}"
		fi
	fi

	if [ -f "${gvm_profile}" ]; then
		if [[ -z `grep 'gvm-init.sh' "${gvm_profile}"` ]]; then
			echo -e "\n${gvm_init_snippet}" >> "${gvm_profile}"
			echo "Updated existing ${gvm_profile}"
		fi
	fi
fi

if [ ! -f "${gvm_bashrc}" ]; then
	echo "#!/bin/bash" > "${gvm_bashrc}"
	echo "${gvm_init_snippet}" >> "${gvm_bashrc}"
	echo "Created and initialised ${gvm_bashrc}"
else
	if [[ -z `grep 'gvm-init.sh' "${gvm_bashrc}"` ]]; then
		echo -e "\n${gvm_init_snippet}" >> "${gvm_bashrc}"
		echo "Updated existing ${gvm_bashrc}"
	fi
fi

echo "Attempt update of zsh profiles..."
if [ ! -f "${gvm_zshrc}" ]; then
	echo "${gvm_init_snippet}" >> "${gvm_zshrc}"
	echo "Created and initialised ${gvm_zshrc}"
else
	if [[ -z `grep 'gvm-init.sh' "${gvm_zshrc}"` ]]; then
		echo -e "\n${gvm_init_snippet}" >> "${gvm_zshrc}"
		echo "Updated existing ${gvm_zshrc}"
	fi
fi

echo -e "\n\n\nAll done!\n\n"

echo "Please open a new terminal, or run the following in the existing one:"
echo ""
echo "    source \"${GVM_DIR}/bin/gvm-init.sh\""
echo ""
echo "Then issue the following command:"
echo ""
echo "    gvm help"
echo ""
echo "Enjoy!!!"
