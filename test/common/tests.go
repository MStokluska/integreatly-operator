package common

import (
	"github.com/integr8ly/integreatly-operator/pkg/apis/integreatly/v1alpha1"
)

// All tests are be linked[1] to the integreatly-test-cases[2] repo by using the same ID
// 1. https://gitlab.cee.redhat.com/integreatly-qe/integreatly-test-cases#how-to-automate-a-test-case-and-link-it-back
// 2. https://gitlab.cee.redhat.com/integreatly-qe/integreatly-test-cases
var (

	HAPPY_PATH_TESTS = []TestSuite{
		//Add all happy path tests to be executed after RHMI installation is completed here
		{
			[]TestCase{
				// Keep test as first on the list, as it ensures that all products are reported as complete
				{"A01 - Verify that all stages in the integreatly-operator CR report completed", TestIntegreatlyStagesStatus},
				{"Test RHMI installation CR metric", TestRHMICRMetrics},
				{"A03 - Verify all namespaces have been created with the correct name", TestNamespaceCreated},
			},
			[]v1alpha1.InstallationType{v1alpha1.InstallationTypeManaged, v1alpha1.InstallationTypeManagedApi},
		},
	}

	IDP_BASED_TESTS = []TestSuite{
		{
			[]TestCase{
			},
			[]v1alpha1.InstallationType{v1alpha1.InstallationTypeManaged, v1alpha1.InstallationTypeManagedApi},
		},
		
	}

	DESTRUCTIVE_TESTS = []TestCase{
		// Add all destructive tests here that should not be executed as part of the happy path tests
		{"J03 - Verify namespaces restored when deleted", TestNamespaceRestoration},
	}
)
