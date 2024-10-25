# To generate the .drone.yml file:
# 1. Modify the *.star definitions
# 2. Login to drone and export the env variables (token and server) shown here: https://drone.grafana.net/account
# 3. Run `make drone`
# More information about this process here: https://github.com/grafana/deployment_tools/blob/master/docs/infrastructure/drone/signing.md
"""
This module returns a Drone configuration including pipelines and secrets.
"""

load("scripts/drone/events/cron.star", "cronjobs")
load("scripts/drone/events/main.star", "main_pipelines")
load("scripts/drone/events/pr.star", "pr_pipelines")
load(
    "scripts/drone/events/release.star",
    "integration_test_pipelines",
    "publish_artifacts_pipelines",
    "publish_npm_pipelines",
    "publish_packages_pipeline",
)
load(
    "scripts/drone/pipelines/publish_images.star",
    "publish_image_pipelines_public",
)
load(
    "scripts/drone/rgm.star",
    "rgm",
)
load("scripts/drone/vault.star", "secrets")
load(
    "scripts/drone/windows.star",
    "windows_manual_pipeline",
)

def main(_ctx):
    return (
        pr_pipelines() +
        main_pipelines() +
        publish_image_pipelines_public() +
        publish_artifacts_pipelines("public") +
        publish_npm_pipelines() +
        publish_packages_pipeline() +
        rgm() +
        integration_test_pipelines() +
        cronjobs() +
        [windows_manual_pipeline()] +
        secrets()
    )
