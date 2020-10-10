pipelineJob("hostverify") {
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
					extensions {
						wipeOutWorkspace()
					}
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
