pipelineJob("Rhel8Build") {
	description()
	keepDependencies(false)
	parameters {
		stringParam("PULL_NUMBER", 200, "")
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
