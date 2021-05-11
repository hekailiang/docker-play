# setup application information
groupId="${groupId:=com.alipay.ap.demo}"
artifactId="${artifactId:=demo}"
appId="${appId:=1512}"
dbSchema="${dbSchema:=demo}"
dockerRepo="${dockerRepo:=registry.cn-shanghai.aliyuncs.com}"

# check environment dependencies
if ! [[ -x "$(command -v java)" ]]; then 
  echo "java must be instsalled first, exit"
  return
fi
if ! [[ -x "$(command -v mvn)" ]]; then 
  echo "maven must be instsalled first, exit"
  return
fi
if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME must be set, exit"
  JAVA_HOME=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'`
  echo "export JAVA_HOME=${${JAVA_HOME:16}%*/jre}"
  return
fi

# prepare embedded database dependencies, only applied for macos
LIBSSL_SOURCE_PATH="/usr/lib/libssl.dylib"
LIBSSL_TARGET_PATH="/usr/local/opt/openssl/lib/libssl.1.0.0.dylib"
LIBCRYPTO_SOURCE_PATH="/usr/lib/libcrypto.dylib"
LIBCRYPTO_TARGET_PATH="/usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib"
if [[ "$(uname)" = "Darwin" ]]; then
  if ! [[ -L "$LIBSSL_TARGET_PATH" ]]; then
    echo "link $LIBSSL_SOURCE_PATH -> $LIBSSL_TARGET_PATH"
    sudo ln -s "$LIBSSL_SOURCE_PATH" "$LIBSSL_TARGET_PATH"
  fi
  if ! [[ -L "$LIBCRYPTO_TARGET_PATH" ]]; then
    echo "link $LIBCRYPTO_SOURCE_PATH -> $LIBCRYPTO_TARGET_PATH"
    sudo ln -s "$LIBCRYPTO_SOURCE_PATH" "$LIBCRYPTO_TARGET_PATH"
  fi
fi

# initialize application skeleton
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
echo "Total used time:" $(( end-start ))"s"

# start application
cd "${artifactId}" && java -jar app/"${artifactId}"-simulator/target/"${artifactId}"-simulator-1.0.0-executable.jar
