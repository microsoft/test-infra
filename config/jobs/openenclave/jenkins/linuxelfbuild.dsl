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
