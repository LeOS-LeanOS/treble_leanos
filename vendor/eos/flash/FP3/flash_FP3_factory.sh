#!/usr/bin/env bash

##########
# This script is created and maintained by
#       Bharath(@teamb58).org
# Feel free to connect for any queries or suggestions.
##########

##########
# This script flashes a software release and completly wipes the device.
#
# The script wipes both user data and the Google factory reset protection
# information. It will unlock the phone, delete the data, and re-lock it.
##########

set -e
set -u

CLEAN_FLASH="true" # Control data wipe behavior. Default is "true".

# Target device info
PRODUCT="Fairphone 3"
PRODUCT_ID="FP3"

# Paths/files
ROOT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
IMAGES_DIR="${ROOT_DIR}"

# Abort the script (and wait for a key to be pressed).
abort_now() {
  echo ""
  read -rp "ERROR: Aborting now (press Enter to terminate)." a
  exit 1
}

# Check for connected phone
find_device() {
  echo "INFO: Looking for connected device(s)..."
  DEVICE_FOUND="false"
  while [ ${DEVICE_FOUND} = "false" ]
  do
    serial_numbers=

    for sn in $("${FASTBOOT_BIN}" devices | grep fastboot | grep -oE '^[[:alnum:]]+')
    do
      # Checking the product ID
      PRODUCT_STRING=$("${FASTBOOT_BIN}" -s "${sn}" getvar product 2>&1)
      # Add serial, if product matches
      if [[ ${PRODUCT_STRING} == *"${PRODUCT_ID}"* ]] || [[ ${PRODUCT_STRING} == *"${PRODUCT_ID_OLD}"* ]]
      then
        serial_numbers="${serial_numbers} $sn"
      fi
    done

    case $(echo "${serial_numbers}" | wc -w | grep -oE '[0-9]+') in
      0)
        echo ""
        echo "WARNING: No ${PRODUCT} found in fastboot mode."
        echo "WARNING: Make sure that a ${PRODUCT} is connected."
        ;;
      1)
          echo "INFO: One ${PRODUCT} in fastboot mode found (serial number: ${sn})."

        DEVICE_FOUND="true"
        break
        ;;
      *)
        echo ""
        echo "WARNING: Several ${PRODUCT}'s in fastboot mode connected."
        echo "WARNING: Please connect only one ${PRODUCT}."
        ;;
    esac

    echo ""
    while true
    do
      read -rp "Do you want to look for a ${PRODUCT} again? [(Y)es/(n)o]: " a
      if [ -z "${a}" ] || [ "${a}" = 'y' ] || [ "${a}" = 'Y' ]
      then
        break
      elif [ "${a}" = 'n' ] || [ "${a}" = 'N' ]
      then
        exit 0
      fi
    done
  done
}

# Check if the device is properly unlocked
check_unlock_status() {
  PHONE_IS_READY=true
  if (fastboot getvar is-userspace 2>&1 | grep -q yes); then
    echo "Info: Your phone is in fastbootD mode."
    if (fastboot getvar unlocked 2>&1 | grep -q no); then
      echo "Error: Your phone is still locked."
      echo "Did you execute 'fastboot flashing unlock'?"
      PHONE_IS_READY=false
    fi
  else
    echo "Info: Your phone is in regular bootloader mode."
    if (fastboot getvar unlocked 2>&1 | grep -q no); then
      echo "Error: Your phone is still locked."
      echo "Did you execute 'fastboot flashing unlock'?"
      PHONE_IS_READY=false
    fi
    if (fastboot oem device-info 2>&1 | grep -q "critical unlocked: false"); then
      echo "Error: Critical partitions are still locked."
      echo "Did you execute 'fastboot flashing unlock_critical'?"
      PHONE_IS_READY=false
    fi
  fi

  if [ "$PHONE_IS_READY" = "false" ]; then
    echo "Error: Your phone is not ready for flashing yet (see above), aborting..."
    exit 1
  fi
}

# Flash (or manipulate) relevant partitions
flash_device() {

  flash_image_ab_or_abort "${sn}" modem "${IMAGES_DIR}/modem.img"
  flash_image_ab_or_abort "${sn}" sbl1 "${IMAGES_DIR}/sbl1.img"
  flash_image_ab_or_abort "${sn}" rpm "${IMAGES_DIR}/rpm.img"
  flash_image_ab_or_abort "${sn}" tz "${IMAGES_DIR}/tz.img"
  flash_image_ab_or_abort "${sn}" devcfg "${IMAGES_DIR}/devcfg.img"
  flash_image_ab_or_abort "${sn}" dsp "${IMAGES_DIR}/dsp.img"
  flash_image_ab_or_abort "${sn}" aboot "${IMAGES_DIR}/aboot.img"

  flash_image_ab_or_abort "${sn}" boot "${IMAGES_DIR}/boot.img"
  flash_image_ab_or_abort "${sn}" dtbo "${IMAGES_DIR}/dtbo.img"
  flash_image_ab_or_abort "${sn}" system "${IMAGES_DIR}/system.img"
  flash_image_ab_or_abort "${sn}" vbmeta "${IMAGES_DIR}/vbmeta.img"
  flash_image_ab_or_abort "${sn}" vendor "${IMAGES_DIR}/vendor.img"
  flash_image_ab_or_abort "${sn}" mdtp "${IMAGES_DIR}/mdtp.img"
  flash_image_ab_or_abort "${sn}" lksecapp "${IMAGES_DIR}/lksecapp.img"
  flash_image_ab_or_abort "${sn}" cmnlib "${IMAGES_DIR}/cmnlib.img"
  flash_image_ab_or_abort "${sn}" cmnlib64 "${IMAGES_DIR}/cmnlib64.img"
  flash_image_ab_or_abort "${sn}" keymaster "${IMAGES_DIR}/keymaster.img"


  if [ "${CLEAN_FLASH}" = "true" ]
  then
    flash_image_or_abort "${sn}" userdata "${IMAGES_DIR}/userdata.img"
  fi

  "$FASTBOOT_BIN" -s "${sn}" --set-active=a

  echo "INFO: Locking bootloader"
  "${FASTBOOT_BIN}" -s "${sn}" oem lock
  echo
  echo "****** READ CAREFULLY ******"
  echo ""
  echo "INFO: The device is waiting for you to lock the bootloader."
  echo "      You can do so on the device itself. Use the volume buttons"
  echo "      to choose the correct option, then the power button to select."
  echo "      The device will then reboot."
  read -rp "      Press any key to close this script." a
  exit 0

}

# Flash an image to a partition. Abort on failure.
# Arguments: <device serial number> <partition name> <image file>
flash_image_or_abort() {
  local retval=0
  "$FASTBOOT_BIN" -s "${1}" flash "${2}" "${3}" || retval=$?

  if [ "${retval}" -ne 0 ]
  then
    echo ""
    echo "ERROR: Could not flash the ${2} partition on device ${1}."
    echo ""
    echo "ERROR: Please unplug the phone, take the battery out, boot the device into"
    echo "ERROR: fastboot mode, and start this script again."
    echo "ERROR: (To get to fastboot mode, press Volume-Down and plug in the USB-C)"
    echo "ERROR: (cable until the fastboot menu appears.)"
    abort_now
  fi
}

# Flash an image to both A and B slot of partition. Abort on failure.
# Arguments: <device serial number> <partition name without slot> <image file>
flash_image_ab_or_abort() {
  flash_image_or_abort "${1}" "${2}_a" "${3}"
  flash_image_or_abort "${1}" "${2}_b" "${3}"
}

# Operating system checks and variable definition
os_checks() {
  case "$(uname -s 2> /dev/null)" in
    Linux|GNU/Linux)
      echo "INFO: You are using a Linux distribution."
      FASTBOOT_BIN="${ROOT_DIR}/bin-linux-x86/fastboot"
      ;;
    msys|MINGW*)
      echo "INFO: You are using MinGW on Windows"
      FASTBOOT_BIN="${ROOT_DIR}/bin-msys/fastboot.exe"
      ;;
    *)
      echo "ERROR: Unsupported operating system (${OSTYPE})."
      echo "ERROR: Only GNU/Linux, and MinGW on Windows are currently supported."
      abort_now
      ;;
  esac
}

# Warn about data wipe, and ask for confirmation
data_wipe_check() {
  if [ "${CLEAN_FLASH}" = "true" ]
  then
    echo ""
    echo "WARNING: Flashing this image wipes all user data and settings on the phone."
    echo " Are you sure you want to wipe data and continue?"
    echo ""
    # Read user's input
    read -rp " Type \"Yes\" (case sensitive) and press enter to wipe data and continue. Else, just press enter: " a
    echo ""
    if [ "_${a:-"No"}" != '_Yes' ]
      # NOTE: $a is being set by the read command above,
      #   so the check for a to be set is mostly redundant
    then
         echo "WARNING: You DID NOT type \"Yes\", proceeding without data wipe."
         echo ""
         CLEAN_FLASH="false"
    else
         echo "WARNING: You typed \"Yes\", proceeding with data wipe."
         CLEAN_FLASH="true"
    fi
  fi
}

echo ""
echo "*** ${PRODUCT} flashing script ***"
echo ""
echo "INFO: The procedure will start soon. Please wait..."
echo "Note that this will detect and flash only on FP3 or FP3+ devices."
sleep 2

# Begin with some OS checks and variable definition
os_checks

# Call function to look for device(s)
# If only one device is found $sn will store its serial number
find_device

# Call function to look for data wipe check
data_wipe_check

# Check if the device is properly unlocked
check_unlock_status

# Flash the device
flash_device
