test_that("legacy s3 block resolves default connection", {
  skip_on_cran()
  skip_if_not_installed("aws.s3")

  tmp <- tempdir()
  old <- getwd()
  setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  yaml::write_yaml(list(
    default = list(
      s3 = list(
        default = list(
          bucket = "my-bucket",
          region = "us-east-1",
          access_key = "abc",
          secret_key = "xyz"
        ),
        default_connection = "default"
      ),
      connections = list(),
      directories = list()
    )
  ), "settings.yml")

  # Prevent real network calls; just ensure client creation works up to credential resolution
  withr::with_envvar(c(
    S3_ACCESS_KEY = "abc",
    S3_SECRET_KEY = "xyz",
    AWS_ACCESS_KEY_ID = "abc",
    AWS_SECRET_ACCESS_KEY = "xyz"
  ), {
    expect_silent(framework:::.resolve_s3_connection())
  })
})
