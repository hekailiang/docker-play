#!/bin/bash
# string formatters
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

info() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

wait() {
  secs=$1
  while [ $secs -gt 0 ]; do
    echo -ne "wait ${tty_red}$secs\033[0Ks${tty_reset} $2\r"
    sleep 1
    : $((secs--))
  done
  echo ""
}

# application settings
groupId="${groupId:-com.alipay.ap.demo}"
artifactId="${artifactId:-${groupId##*.}}"
version="${version:-1.0.0}"
dbSchema="${dbSchema:-${artifactId}}"
appId="${appId:-1200}"
dockerRepo="${dockerRepo:-registry.cn-shanghai.aliyuncs.com}"
dockerNs="${dockerNs:-glocal}"
startApp="${startApp:-yes}"

echo "please confirm ${artifactId} application information:"
info "groupId: ${groupId}"
info "artifactId: ${artifactId}"
info "version: ${version}"
info "dbSchema: ${dbSchema}"
info "appId: ${appId}"
info "dockerRepo: ${dockerRepo}"
info "dockerNs: ${dockerNs}"
echo -n "continue to initializing application (${tty_bold}y${tty_reset}/n)? "
read answer
if [[ "${answer:=y}" == "${answer#[Yy]}" ]] ;then
   echo "goodbye!"
   exit 1
fi

info "checking ${artifactId} application dependencies ..."
if [[ "$appId" =~ [0-9]{4} ]]; then
  echo "appId..............checked"
else
  warn "appId must be 4 digits number, exit"
  exit 1
fi
if [[ -x "$(command -v java)" ]]; then
  echo "jdk................checked"
else
  warn "java must be instsalled first, exit"
  exit 1
fi
if [[ -x "$(command -v mvn)" ]]; then
  echo "maven..............checked"
else
  warn "maven must be instsalled first, exit"
  exit 1
fi
if [[ -z "${JAVA_HOME}" ]]; then
  warn "JAVA_HOME must be set, exit"
  JRE_HOME=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'`
  info "run following command or add into .bashrc or .zshrc"
  info "export JAVA_HOME=${${JRE_HOME:16}%*/jre}"
  exit 1
else
  echo "JAVA_HOME..........checked"
fi

LIBSSL_SOURCE_PATH="/usr/lib/libssl.dylib"
LIBSSL_TARGET_PATH="/usr/local/opt/openssl/lib/libssl.1.0.0.dylib"
LIBCRYPTO_SOURCE_PATH="/usr/lib/libcrypto.dylib"
LIBCRYPTO_TARGET_PATH="/usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib"
if [[ "$(uname)" = "Darwin" ]]; then
  if ! [[ -L "$LIBSSL_TARGET_PATH" ]]; then
    info "setup required library ${LIBSSL_TARGET_PATH##*/} for mariadb (which may request your password)"
    info "sudo ln -s $LIBSSL_SOURCE_PATH $LIBSSL_TARGET_PATH"
    sudo ln -s "$LIBSSL_SOURCE_PATH" "$LIBSSL_TARGET_PATH"
  fi
  if ! [[ -L "$LIBCRYPTO_TARGET_PATH" ]]; then
    info "setup required library ${LIBCRYPTO_TARGET_PATH##*/} for mariadb (which may request your password)"
    info "sudo ln -s $LIBCRYPTO_SOURCE_PATH $LIBCRYPTO_TARGET_PATH"
    sudo ln -s "$LIBCRYPTO_SOURCE_PATH" "$LIBCRYPTO_TARGET_PATH"
  fi
fi
echo "libssl/libcrypto...checked"

info "initializing ${artifactId} application (which may take a while) ..."
start=`date +%s`;
archetypeRepository=http://mvn.dev.alipayplus.alipay.net/nexus/content/groups/Core-Group && \
if [[ -d .mvn ]]; then rm -rf .mvn; fi && \
if [[ -d "${artifactId}" ]]; then rm -rf "${artifactId}"; fi && \
mkdir -p .mvn && \
echo '<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <localRepository>.mvn/repository</localRepository>
	<profiles>
        <profile>
            <id>alipayplus_dev</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <repositories>
                <repository>
                    <id>central</id>
                    <url>'"${archetypeRepository}"'</url>
                </repository>
            </repositories>
            <pluginRepositories>
                <pluginRepository>
                    <id>central</id>
                    <url>'"${archetypeRepository}"'</url>
                </pluginRepository>
            </pluginRepositories>
        </profile>
    </profiles>
</settings>' > .mvn/settings.xml && \
mvn -q -s .mvn/settings.xml -gs .mvn/settings.xml archetype:generate -DarchetypeGroupId=com.alipay.archetypes \
    -DarchetypeArtifactId=glocal-sofaboot-archetype -DarchetypeVersion=4.2.2 -DarchetypeCatalog=local -DinteractiveMode=false \
    -DgroupId="${groupId}" -DartifactId="${artifactId}" -Dversion="${version}" -DappId="${appId}" -DdbSchema="${dbSchema}" \
    -DdockerRepo="${dockerRepo}" -DdockerNs="${dockerNs}" && \
rm -rf .mvn
end=`date +%s`;
info "initialize ${artifactId} application done, spent ${tty_red}"$(( end-start ))"s${tty_reset}"

IDEA=`ls -1d /Applications/IntelliJ\ * | tail -n1`
if [[ -n "$IDEA" ]]; then
  info "open \"Project Preferences(CMD+,)\", locate \"Build, Execution, Deployment > Build Tools > Maven\" tab"
  info "set \"User settings file\" to \"$PWD/${artifactId}/.mvn/settings.xml\""
  info "set \"Local repository\" to \"$PWD/${artifactId}/.mvn/repository\""
  wait 10 "to open IDEA with ${artifactId} application ..."
  open -a "$IDEA" "${artifactId}/pom.xml"
fi

if [[ "$startApp" =~ ^(y|Y).* ]]; then
  wait 10 "to continue launching ${artifactId} application ..."
  info "launching ${artifactId} application ..."
  info "install mariadb database at ${artifactId}/.database"
  JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
  cd "${artifactId}" && java "$JAVA_OPTS" -jar -Dlogging.level."${groupId}"=INFO app/"${artifactId}"-simulator/target/"${artifactId}"-simulator-1.0.0-executable.jar
fi
