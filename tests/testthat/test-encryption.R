test_that("password-based encryption core functions work", {
  skip_if_not_installed("sodium")

  # Test password derivation
  password <- "test-password-123"
  salt <- sodium::random(32)

  key1 <- framework:::.derive_key_from_password(password, salt)
  expect_equal(length(key1), 32)

  # Same password + salt = same key
  key2 <- framework:::.derive_key_from_password(password, salt)
  expect_identical(key1, key2)

  # Different salt = different key
  salt2 <- sodium::random(32)
  key3 <- framework:::.derive_key_from_password(password, salt2)
  expect_false(identical(key1, key3))
})

test_that("encryption and decryption round-trip works", {
  skip_if_not_installed("sodium")

  password <- "my-secret-password"
  original_data <- charToRaw("Hello, World! This is a test message.")

  # Encrypt
  encrypted <- framework:::.encrypt_with_password(original_data, password)

  # Check structure
  expect_true(length(encrypted) > 63) # Header + ciphertext
  expect_identical(encrypted[1:6], charToRaw("FWENC1")) # Magic bytes

  # Decrypt
  decrypted <- framework:::.decrypt_with_password(encrypted, password)
  expect_identical(decrypted, original_data)
})

test_that("decryption fails with wrong password", {
  skip_if_not_installed("sodium")

  password <- "correct-password"
  wrong_password <- "wrong-password"
  original_data <- charToRaw("Secret data")

  encrypted <- framework:::.encrypt_with_password(original_data, password)

  expect_error(
    framework:::.decrypt_with_password(encrypted, wrong_password),
    "Failed to decrypt"
  )
})

test_that("encrypted file detection works", {
  skip_if_not_installed("sodium")

  temp_dir <- tempdir()

  # Create encrypted file
  encrypted_file <- file.path(temp_dir, "encrypted.bin")
  password <- "test-pass"
  data <- charToRaw("test data")
  encrypted_data <- framework:::.encrypt_with_password(data, password)
  writeBin(encrypted_data, encrypted_file)

  # Create non-encrypted file
  plain_file <- file.path(temp_dir, "plain.txt")
  writeLines("plain text", plain_file)

  # Test detection
  expect_true(framework:::.is_encrypted_file(encrypted_file))
  expect_false(framework:::.is_encrypted_file(plain_file))

  # Cleanup
  unlink(encrypted_file)
  unlink(plain_file)
})

test_that("data_save and data_load work with encryption", {
  skip_if_not_installed("sodium")

  # Setup test project
  test_dir <- create_test_project(type = "project")
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create test data
  test_data <- data.frame(
    id = 1:5,
    value = c("A", "B", "C", "D", "E"),
    stringsAsFactors = FALSE
  )

  password <- "data-encryption-password"

  # Save encrypted data
  suppressMessages(
    data_save(
      test_data,
      path = "test.encrypted",
      type = "rds",
      encrypted = TRUE,
      password = password
    )
  )

  # Verify file exists and is encrypted
  # Path "test.encrypted" creates "data/test/encrypted.rds"
  data_file <- file.path("data", "test", "encrypted.rds")
  expect_true(file.exists(data_file))
  expect_true(framework:::.is_encrypted_file(data_file))

  # Load encrypted data by file path (bypassing catalog)
  loaded_data <- data_load(data_file, password = password)
  expect_identical(loaded_data, test_data)

  # Auto-detection: load without specifying encryption
  loaded_auto <- data_load(data_file, password = password)
  expect_identical(loaded_auto, test_data)

  # Wrong password should fail
  expect_error(
    data_load(data_file, password = "wrong-password"),
    "Failed to decrypt"
  )
})

test_that("result encryption uses same password-based encryption", {
  skip_if_not_installed("sodium")

  # NOTE: result_save and result_get use the same .encrypt_with_password
  # and .decrypt_with_password functions as data_save/data_load.
  # The encryption logic is identical, just applied to serialized R objects.
  # This test verifies the raw encryption works; integration tests in
  # test-results.R cover the full result_save/result_get workflow.

  # Create test result
  test_result <- list(
    model_type = "linear",
    coefficients = c(1.2, 3.4, 5.6),
    r_squared = 0.85
  )

  password <- "result-test-password"

  # Simulate what result_save does: serialize and encrypt
  serialized <- serialize(test_result, NULL)
  encrypted <- framework:::.encrypt_with_password(serialized, password)

  # Verify encryption
  expect_true(length(encrypted) > 63)  # Has header
  expect_identical(encrypted[1:6], charToRaw("FWENC1"))  # Magic bytes

  # Simulate what result_get does: decrypt and unserialize
  decrypted <- framework:::.decrypt_with_password(encrypted, password)
  result <- unserialize(decrypted)

  # Verify round-trip
  expect_identical(result, test_result)
})

test_that("CSV data can be encrypted as raw bytes", {
  skip_if_not_installed("sodium")

  # Create test data with various types
  test_data <- data.frame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    score = c(95.5, 87.3, 92.1),
    passed = c(TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  password <- "csv-encryption-test"

  # Simulate CSV encryption: write to temp, read raw, encrypt
  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  csv_raw <- readBin(temp_csv, "raw", n = file.info(temp_csv)$size)

  # Encrypt the CSV bytes
  encrypted <- framework:::.encrypt_with_password(csv_raw, password)

  # Verify encryption
  expect_true(length(encrypted) > length(csv_raw))
  expect_identical(encrypted[1:6], charToRaw("FWENC1"))

  # Decrypt and parse
  decrypted <- framework:::.decrypt_with_password(encrypted, password)
  expect_identical(decrypted, csv_raw)

  # Parse back to data frame
  temp_decrypt <- tempfile(fileext = ".csv")
  writeBin(decrypted, temp_decrypt)
  loaded_data <- readr::read_csv(temp_decrypt, show_col_types = FALSE)

  # Verify data integrity (convert tibble to data.frame for comparison)
  expect_equal(as.data.frame(loaded_data), test_data)

  # Cleanup
  unlink(temp_csv)
  unlink(temp_decrypt)
})

test_that("environment variable password retrieval works", {
  skip_if_not_installed("sodium")

  # Save original env var
  original_pwd <- Sys.getenv("ENCRYPTION_PASSWORD", unset = NA)
  on.exit({
    if (is.na(original_pwd)) {
      Sys.unsetenv("ENCRYPTION_PASSWORD")
    } else {
      Sys.setenv(ENCRYPTION_PASSWORD = original_pwd)
    }
  }, add = TRUE)

  # Set test password
  Sys.setenv(ENCRYPTION_PASSWORD = "env-test-password")

  # Should retrieve from environment
  pwd <- framework:::.get_encryption_password(prompt = FALSE)
  expect_equal(pwd, "env-test-password")

  # Missing env var should error in non-interactive mode
  Sys.unsetenv("ENCRYPTION_PASSWORD")
  expect_error(
    framework:::.get_encryption_password(prompt = FALSE),
    "ENCRYPTION_PASSWORD not found"
  )
})

test_that("salt uniqueness ensures different ciphertexts", {
  skip_if_not_installed("sodium")

  password <- "same-password"
  data <- charToRaw("same data")

  # Encrypt twice with same password
  encrypted1 <- framework:::.encrypt_with_password(data, password)
  encrypted2 <- framework:::.encrypt_with_password(data, password)

  # Ciphertexts should be different (different salts)
  expect_false(identical(encrypted1, encrypted2))

  # But both should decrypt correctly
  decrypted1 <- framework:::.decrypt_with_password(encrypted1, password)
  decrypted2 <- framework:::.decrypt_with_password(encrypted2, password)
  expect_identical(decrypted1, data)
  expect_identical(decrypted2, data)
})

test_that("corrupted encrypted data fails gracefully", {
  skip_if_not_installed("sodium")

  password <- "test-password"
  data <- charToRaw("test data")
  encrypted <- framework:::.encrypt_with_password(data, password)

  # Corrupt the ciphertext
  corrupted <- encrypted
  corrupted[length(corrupted)] <- as.raw(255)

  # Should fail with clear error
  expect_error(
    framework:::.decrypt_with_password(corrupted, password),
    "Failed to decrypt"
  )
})

test_that("empty and short files are rejected", {
  skip_if_not_installed("sodium")

  temp_dir <- tempdir()

  # Empty file
  empty_file <- file.path(temp_dir, "empty.bin")
  writeBin(raw(0), empty_file)
  expect_false(framework:::.is_encrypted_file(empty_file))

  # Too short file
  short_file <- file.path(temp_dir, "short.bin")
  writeBin(charToRaw("FW"), short_file)
  expect_false(framework:::.is_encrypted_file(short_file))

  # Cleanup
  unlink(empty_file)
  unlink(short_file)
})
