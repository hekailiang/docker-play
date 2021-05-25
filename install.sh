#!/bin/bash
#-u treat unset parameters as an error, rather than substituting them with a blank
#-e if a simple command fails, errors or returns an exit status value >0
set -ue
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

abort() {
  printf "%s\n" "$@"
  exit 1
}

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
alipayVersion="${alipayVersion:-no}"
dockerRepo="${dockerRepo:-registry.cn-shanghai.aliyuncs.com}"
dockerNs="${dockerNs:-glocal}"
startApp="${startApp:-yes}"

echo "please confirm ${artifactId} application information:"
info "groupId: ${groupId}"
info "artifactId: ${artifactId}"
info "version: ${version}"
info "dbSchema: ${dbSchema}"
info "appId: ${appId}"
info "alipayVersion: ${alipayVersion}"
info "dockerRepo: ${dockerRepo}"
info "dockerNs: ${dockerNs}"
echo -n "continue to initializing application (${tty_bold}y${tty_reset}/n)? "
read answer
if [[ "${answer:=y}" == "${answer#[Yy]}" ]] ;then
   abort "goodbye!"
fi

info "checking ${artifactId} application dependencies ..."
echo -n "appId..............checked"
if [[ "$appId" =~ [0-9]{4} ]]; then
  echo "✅"
else
  echo "❌"
  warn "appId must be 4 digits number"
  abort "exit"
fi

echo -n "jdk................checked"
if [[ -x "$(command -v java)" ]]; then
  echo "✅"
else
  echo "❌"
  warn "java must be installed first, highly recommend sdkman (https://sdkman.io/) for sdk management"
  abort "exit"
fi

echo -n "maven..............checked"
if [[ -x "$(command -v mvn)" ]]; then
  echo "✅"
else
  echo "❌"
  warn "maven must be installed firs, highly recommend sdkman (https://sdkman.io/) for sdk management"
  abort "exit"
fi

echo -n "JAVA_HOME..........checked"
if [[ -z "${JAVA_HOME-}" ]]; then
  echo "❌"
  warn "JAVA_HOME must be set"
  TEST_JAVA_HOME=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'`
  TEST_JAVA_HOME=${TEST_JAVA_HOME:16}
  info "run following command or add into .bashrc or .zshrc"
  info "export JAVA_HOME=${TEST_JAVA_HOME%*/jre}"
  abort "exit"
else
  echo "✅"
fi

echo -n "PORT 3316..........checked"
OCCUPIED_PID=$(lsof -nP -iTCP:3316 | grep LISTEN | awk '{print $2}')
if [[ -n "$OCCUPIED_PID" ]]; then
  echo "❌"
  echo "port 3316 is occupied by process $OCCUPIED_PID"
  ps -ef | grep "$OCCUPIED_PID" | grep -v grep
  wait 10 "to kill process $OCCUPIED_PID ..."
  kill -9 "$OCCUPIED_PID"
else
  echo "✅"
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
echo "libssl/libcrypto...checked✅"

info "initializing ${artifactId} application (which may take a while) ..."
start=`date +%s`;
archetypeRepository=http://mvn.dev.alipayplus.alipay.net/nexus/content/groups/Core-Group && \
if [[ -d .mvn ]]; then warn "remove cached .mvn result"; rm -rf .mvn; fi && \
if [[ -d "${artifactId}" ]]; then warn "remove duplicated project ${artifactId}"; rm -rf "${artifactId}"; fi && \
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
    -DalipayVersion="${alipayVersion}" -DdockerRepo="${dockerRepo}" -DdockerNs="${dockerNs}" && \
rm -rf .mvn
end=`date +%s`;
info "initialize ${artifactId} application done, spent ${tty_red}"$(( end-start ))"s${tty_reset}"
info "🌹🌹🌹 Have a wonderful day 🌹🌹🌹"
echo ""

unset VSCODE IDEA ECLIPSE SUBLIME
if [[ -n "${VSCODE:=`ls -1d /Applications/Visual\ Studio\ Code* | tail -n1`}" ]]; then
  wait 10 "to open ${artifactId} application with VSCODE ..."
  open -a "$VSCODE" "${artifactId}/${artifactId}.code-workspace"
elif [[ -n "${IDEA:=`ls -1d /Applications/IntelliJ\ * | tail -n1`}" ]]; then
  info "open \"Project Preferences(CMD+,)\", find \"Build, Execution, Deployment > Build Tools > Maven\" tab"
  info "set \"User settings file\" to \"$PWD/${artifactId}/.mvn/settings.xml\""
  info "set \"Local repository\" to \"$PWD/${artifactId}/.mvn/repository\""
  wait 10 "to open ${artifactId} application with IDEA ..."
  open -a "$IDEA" "${artifactId}/pom.xml"
elif [[ -n "${ECLIPSE:=`ls -1d /Applications/Eclipse\ */ | tail -n1`}" ]]; then
  wait 10 "to open ${artifactId} application with ECLIPSE ..."
  open -a "$ECLIPSE" "${artifactId}"
elif [[ -n "${SUBLIME:=`ls -1d /Applications/Sublime\ Text* | tail -n1`}" ]]; then
  wait 10 "to open ${artifactId} application with SUBLIME ..."
  open -a "$SUBLIME" "${artifactId}"
else
  open "${artifactId}"
fi
echo ""

if [[ "$startApp" =~ ^(y|Y).* ]]; then
  wait 10 "to continue launching ${artifactId} application ..."
  info "launching ${artifactId} application ..."
  info "install mariadb database at ${artifactId}/.database"
  JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
  cd "${artifactId}" && java "$JAVA_OPTS" -jar -Dlogging.level."${groupId}"=INFO app/"${artifactId}"-simulator/target/"${artifactId}"-simulator-1.0.0-executable.jar
fi
