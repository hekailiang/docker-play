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

groupId="${groupId:-com.alipay.ap.demo}"
artifactId="${artifactId:-${groupId##*.}}"
dbSchema="${dbSchema:-${artifactId}}"
appId="${appId:-1200}"
dockerRepo="${dockerRepo:-registry.cn-shanghai.aliyuncs.com}"
echo "please confirm ${artifactId} application information:"
info "groupId: ${groupId}"
info "artifactId: ${artifactId}"
info "dbSchema: ${dbSchema}"
info "appId: ${appId}"
echo -n "continue to initializing application (${tty_bold}y${tty_reset}/n)? "
read answer
if [[ "$answer" == "${answer#[Yy]}" ]] ;then
   echo "goodbye!"
   exit 1
fi

info "checking ${artifactId} application dependencies ..."
if ! [[ -x "$(command -v java)" ]]; then 
  warn "java must be instsalled first, exit"
  exit 1
fi
if ! [[ -x "$(command -v mvn)" ]]; then 
  warn "maven must be instsalled first, exit"
  exit 1
fi
if [[ -z "${JAVA_HOME}" ]]; then
  warn "JAVA_HOME must be set, exit"
  JRE_HOME=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'`
  info "run following command or add into .bashrc or .zshrc"
  info "export JAVA_HOME=${${JRE_HOME:16}%*/jre}"
  exit 1
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

info "initializing ${artifactId} application ..."
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
mvn -s .mvn/settings.xml -gs .mvn/settings.xml archetype:generate -DarchetypeGroupId=com.alipay.archetypes -DarchetypeArtifactId=glocal-sofaboot-archetype \
    -DarchetypeVersion=4.2.2 -DarchetypeCatalog=local -DinteractiveMode=false \
    -DgroupId="${groupId}" -DartifactId="${artifactId}" -DappId="${appId}" -DdbSchema="${dbSchema}" -DdockerRepo="${dockerRepo}" && \
rm -rf .mvn
end=`date +%s`;
info "initialize application spent " $(( end-start ))"s"

secs=10
while [ $secs -gt 0 ]; do
   echo -ne "wait ${tty_red}$secs\033[0Ks${tty_reset} to continue launching application ...\r"
   sleep 1
   : $((secs--))
done
echo ""
sleep 1

info "launching ${artifactId} application ..."
info "install mariadb database at ${artifactId}/.database"
cd "${artifactId}" && java -jar app/"${artifactId}"-simulator/target/"${artifactId}"-simulator-1.0.0-executable.jar
