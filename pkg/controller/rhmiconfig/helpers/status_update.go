package helpers

import (
	"context"
	"strconv"
	"strings"
	"time"

	integreatlyv1alpha1 "github.com/integr8ly/integreatly-operator/pkg/apis/integreatly/v1alpha1"

	olmv1alpha1 "github.com/operator-framework/operator-lifecycle-manager/pkg/api/apis/operators/v1alpha1"
	k8sclient "sigs.k8s.io/controller-runtime/pkg/client"
)

const WINDOW = 6

func UpdateStatus(ctx context.Context, client k8sclient.Client, config *integreatlyv1alpha1.RHMIConfig, installplan *olmv1alpha1.InstallPlan, targetVersion string) error {
	// Calculate the next maintenance window based on the maintenance schedule
	if config.Spec.Maintenance.ApplyFrom != "" {
		mtStart, _, err := getWeeklyWindowFromNow(config.Spec.Maintenance.ApplyFrom, time.Hour*WINDOW)
		if err != nil {
			return err
		}

		config.Status.Maintenance.ApplyFrom = mtStart.Format("2-1-2006 15:04")
		config.Status.Maintenance.Duration = strconv.Itoa(WINDOW) + "hrs"
	}

	config.Status.TargetVersion = targetVersion

	// If the install plan was approved, simply clear the status
	if installplan.Spec.Approved {
		config.Status.Upgrade.Scheduled.For = ""

		return client.Status().Update(ctx, config)
	}

	// Calculate the upgrade schedule based on the spec:
	// We can assume there's no error parsing the value as it was validated
	notBeforeDays := *config.Spec.Upgrade.NotBeforeDays
	waitForMaintenance := *config.Spec.Upgrade.WaitForMaintenance

	upgradeSchedule := installplan.ObjectMeta.CreationTimestamp.Time.
		Add(daysDuration(notBeforeDays))

	if waitForMaintenance {
		var err error
		upgradeSchedule, _, err = getWeeklyWindow(upgradeSchedule, config.Spec.Maintenance.ApplyFrom, time.Hour*WINDOW)
		if err != nil {
			return err
		}
	}

	// Update the upgrade status
	config.Status.Upgrade = integreatlyv1alpha1.RHMIConfigStatusUpgrade{
		Scheduled: &integreatlyv1alpha1.UpgradeSchedule{
			For: upgradeSchedule.Format(integreatlyv1alpha1.DateFormat),
		},
	}

	return client.Status().Update(ctx, config)
}

func getWeeklyWindow(from time.Time, windowStartStr string, duration time.Duration) (time.Time, time.Time, error) {
	var shortDays = map[string]int{
		"sun": 0,
		"mon": 1,
		"tue": 2,
		"wed": 3,
		"thu": 4,
		"fri": 5,
		"sat": 6,
	}

	windowSegments := strings.Split(windowStartStr, " ")
	windowDay := windowSegments[0]

	windowTimeSegments := strings.Split(windowSegments[1], ":")
	windowHour, err := strconv.Atoi(windowTimeSegments[0])
	if err != nil {
		return time.Time{}, time.Time{}, err
	}
	windowMin, err := strconv.Atoi(windowTimeSegments[1])
	if err != nil {
		return time.Time{}, time.Time{}, err
	}

	//calculate how far away from maintenance day today is, within the current week
	dayDiff := shortDays[strings.ToLower(windowDay)] - int(from.Weekday())
	if dayDiff < 0 {
		dayDiff = 7 + dayDiff
	}

	//negative days roll back the month and year, tested here: https://play.golang.org/p/gBBHw49nH1b
	windowStart := time.Date(from.Year(), from.Month(), from.Day(), windowHour, windowMin, 0, 0, time.UTC)
	windowStart = windowStart.Add(daysDuration(dayDiff))
	return windowStart, windowStart.Add(duration), nil
}

func getWeeklyWindowFromNow(windowStartStr string, duration time.Duration) (time.Time, time.Time, error) {
	return getWeeklyWindow(time.Now().UTC(), windowStartStr, duration)
}

func daysDuration(numberOfDays int) time.Duration {
	return time.Duration(numberOfDays) * 24 * time.Hour
}
