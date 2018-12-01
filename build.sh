#!/bin/sh

createKeystore()
{
	echo "Arquivo .keystore nao existe!"
	condtion=""

  while [ "$condtion" != "yes" ] && [ "$condtion" != "no" ]; do
		echo -e "Deseja gerar .keystore? (yes) or (no)"; read condtion

		if [ "$condtion" = "no" ]; then
			exit;
		fi
	done

	keytool -genkey -v -keystore $FILE_KEYSTORE_PATH -alias $DIRECTORY -keyalg RSA -keysize 2048 -validity 10000	

	echo "Arquivo .keystore criado com sucesso!"
	condtion=""

	while [ "$condtion" != "yes" ] && [ "$condtion" != "no" ]; do
		echo -e "Deseja continuar com o processo de build? (yes) or (no)"; read condtion

		if [ "$condtion" = "no" ]; then
			exit;
		fi
	done
}

removeTempFiles()
{
	FILE_PATH=$1
	if [ -f "$FILE_PATH" ]; then
		rm $FILE_PATH
	fi
}

# PROJECT FOLDER
DIRECTORY=""

while [ ! -d "$DIRECTORY" ]; do
	echo -e "Digite o nome da pasta do aplicativo:"; read DIRECTORY

	if [ ! -d "$DIRECTORY" ]; then
	  echo "A pasta nao existe!"
	fi
done

# PROJECT RELEASE FOLDER
DIRECTORY_RELEASE="$DIRECTORY-release"

# CHECK IF KEYSTORE EXIST
FILE_KEYSTORE_PATH="$DIRECTORY_RELEASE/$DIRECTORY.keystore"
if [ ! -f "$FILE_KEYSTORE_PATH" ]; then
	createKeystore "$DIRECTORY" "$FILE_KEYSTORE_PATH"
fi

#REMOVE BUILD TEMP FILES
FILE_UNSIGNED_PATH="$DIRECTORY_RELEASE/app-release-unsigned.apk"
removeTempFiles $FILE_UNSIGNED_PATH

FILE_UNALIGNED_PATH="$DIRECTORY_RELEASE/app-release-unaligned.apk"
removeTempFiles $FILE_UNALIGNED_PATH

FILE_FINAL_PATH="$DIRECTORY_RELEASE/$DIRECTORY.apk"
removeTempFiles $FILE_FINAL_PATH

#BUILD
cd $DIRECTORY 
ionic cordova build android --prod --release
cd ../

#COPY BUILD
FILE_UNSIGNED_PROJECT_PATH="$DIRECTORY\platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk"
cp $FILE_UNSIGNED_PROJECT_PATH "$DIRECTORY_RELEASE"
jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 -keystore "$FILE_KEYSTORE_PATH" "$FILE_UNSIGNED_PATH" -signedjar "$FILE_UNALIGNED_PATH" "$DIRECTORY"
zipalign -v 4 "$FILE_UNALIGNED_PATH" "$FILE_FINAL_PATH"

#REMOVE TEMP FILES
removeTempFiles $FILE_UNSIGNED_PATH
removeTempFiles $FILE_UNALIGNED_PATH