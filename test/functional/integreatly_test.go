package functional

import (
	"os"
	"testing"

	"k8s.io/client-go/rest"

	"github.com/integr8ly/integreatly-operator/test/common"
	runtimeConfig "sigs.k8s.io/controller-runtime/pkg/client/config"
)

func TestIntegreatly(t *testing.T) {
	config, err := runtimeConfig.GetConfig()
	config.Impersonate = rest.ImpersonationConfig{
		UserName: "system:admin",
		Groups:   []string{"system:authenticated"},
	}
	if err != nil {
		t.Fatal(err)
	}
	installType, err := common.GetInstallType(config)
	if err != nil {
		t.Fatalf("failed to get install type, err: %s, %v", installType, err)
	}
	t.Run("Integreatly Happy Path Tests", func(t *testing.T) {


		// get happy path test cases according to the install type
		happyPathTestCases := common.GetHappyPathTestCases(installType)

		// running HAPPY_PATH_TESTS tests cases
		common.RunTestCases(happyPathTestCases, t, config)

		// running functional tests
		common.RunTestCases(FUNCTIONAL_TESTS, t, config)
	})

}
