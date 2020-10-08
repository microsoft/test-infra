pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", false, "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/oeedger8r-cpp/jenkins/Rhel8Build.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("WindowsBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/oeedger8r-cpp/jenkins/WindowsBuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", false, "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/openenclave-mbedtls")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/openenclave-mbedtls/jenkins/Rhel8Build.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("WindowsBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/oeedger8r-cpp/jenkins/WindowsBuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("hostverify") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 3617, "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/hostverify.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("hostverifyPackage") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 3617, "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/hostverifypackage")
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/hostverifyPackage.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("linuxelfbuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 3617, "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("LVI_MITIGATION", "ControlFlow", "")
		stringParam("LVI_MITIGATION_SKIP_TESTS", "OFF", "")
		stringParam("COMPILER", "clang-7", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/linuxelfbuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 3617, "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/addORRhel8")
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/Rhel8Build.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("WindowsBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 3617, "")
		booleanParam("TEST_INFRA", false, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/WindowsBuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

job("jenkins-ping") {
	description()
	keepDependencies(false)
	disabled(false)
	concurrentBuild(false)
	steps {
		shell("echo \"pong\"")
	}
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('1')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("origin/master")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/oeedger8r-cpp/jenkins/Rhel8Build.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("origin/master")
					branch("*/openenclave-mbedtls")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/openenclave-mbedtls/jenkins/Rhel8Build.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("WindowsBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("origin/master")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/oeedger8r-cpp/jenkins/WindowsBuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("Windows2019DockerBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("*/master")
				}
			}
			scriptPath("config/jobs/test-infra/jenkins/build2019.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

job("always-pass") {
	description()
	keepDependencies(false)
	disabled(false)
	concurrentBuild(true)
	steps {
		shell("echo \"Success!\"")
	}
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('-1')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

job("always-fail") {
	description()
	keepDependencies(false)
	disabled(false)
	concurrentBuild(false)
	steps {
		shell("""if [ -f "\$file" ]
then
    echo "\$file found."
else
    echo "\$file not found."
    exit 1
fi""")
	}
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('-1')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("WindowsBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/WindowsBuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/Rhel8Build.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("linuxelfbuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("LVI_MITIGATION", "ControlFlow", "")
		stringParam("LVI_MITIGATION_SKIP_TESTS", "OFF", "")
		stringParam("COMPILER", "clang-7", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/linuxelfbuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("hostverifyPackage") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 161, "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/hostverifyPackage.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("hostverify") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("LINUX_VERSION", 1804, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/openenclave/jenkins/hostverify.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('10')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}

pipelineJob("WindowsBuild") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", "master", "")
		booleanParam("TEST_INFRA", true, "")
		stringParam("WINDOWS_VERSION", 2019, "")
		stringParam("BUILD_TYPE", "Release", "")
		stringParam("EXTRA_CMAKE_ARGS", "", "")
	}
	definition {
		cpsScm {
			scm {
				git {
					remote {
						github("openenclave-ci/test-infra", "https")
					}
					branch("origin/pr/\${PULL_NUMBER}")
					branch("origin/master")
					branch("*/master")
					extensions {
						wipeOutWorkspace()
					}
				}
			}
			scriptPath("config/jobs/oeedger8r-cpp/jenkins/WindowsBuild.Jenkinsfile")
		}
	}
	disabled(false)
	configure {
		it / 'properties' / 'jenkins.model.BuildDiscarderProperty' {
			strategy {
				'daysToKeep'('2')
				'numToKeep'('50')
				'artifactDaysToKeep'('-1')
				'artifactNumToKeep'('-1')
			}
		}
	}
}
