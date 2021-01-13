String dockerImage(String tag, String dockerfile = ".jenkins/Dockerfile", String buildArgs = "") {
    return docker.build(tag, "${buildArgs} -f ${dockerfile} .")
}

return this
