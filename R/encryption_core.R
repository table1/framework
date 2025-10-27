#' Encryption core functions for Framework
#'
#' Password-based encryption using libsodium (Ansible Vault style).
#' Derives cryptographic keys from user passwords using scrypt (memory-hard KDF).
#'
#' @keywords internal

# Constants
.MAGIC_BYTES <- charToRaw("FWENC1")
.MAGIC_SIZE <- 6
.SALT_SIZE <- 32  # For scrypt key derivation
.NONCE_SIZE <- 24  # For sodium
.HEADER_SIZE <- 63  # 6 (magic) + 32 (salt) + 24 (nonce) + 1 (reserved)
#' Derive encryption key from password
#'
#' Uses libsodium's scrypt implementation to derive a 32-byte key from a password.
#' Scrypt is memory-hard, making it resistant to hardware brute-force attacks.
#' Uses sodium's default parameters (N = 16384, r = 8, p = 1).
#'
#' @param password Character string password
#' @param salt Raw vector (32 bytes) for key derivation
#' @return Raw vector (32 bytes) - encryption key
#' @keywords internal
.derive_key_from_password <- function(password, salt) {
  checkmate::assert_string(password, min.chars = 1)
  checkmate::assert_raw(salt)

  if (length(salt) != .SALT_SIZE) {
    stop(sprintf("Salt must be exactly %d bytes, got %d", .SALT_SIZE, length(salt)))
  }

  # Check sodium available
  if (!requireNamespace("sodium", quietly = TRUE)) {
    stop(
      "Key derivation requires the sodium package.\n\n",
      "Install with: install.packages('sodium')"
    )
  }

  # Use scrypt to derive key (memory-hard KDF)
  key <- sodium::scrypt(
    charToRaw(password),
    salt = salt,
    size = 32
  )

  key
}

#' Get encryption password
#'
#' Gets encryption password from environment variable or prompts user.
#'
#' @param prompt Logical. If TRUE and interactive, prompt for password
#' @return Character string password
#' @keywords internal
.get_encryption_password <- function(prompt = TRUE) {
  # Try environment variable first
  pwd <- Sys.getenv("ENCRYPTION_PASSWORD", "")

  if (pwd == "") {
    if (prompt && interactive()) {
      pwd <- readline("Encryption password: ")

      if (pwd == "") {
        stop("Password cannot be empty")
      }
    } else {
      stop(
        "ENCRYPTION_PASSWORD not found in environment.\n\n",
        "Set with: Sys.setenv(ENCRYPTION_PASSWORD = \"your-password\")\n",
        "Or add to .env file: ENCRYPTION_PASSWORD=your-password"
      )
    }
  }

  pwd
}

#' Encrypt data with password
#'
#' Encrypts raw data using password-derived key.
#'
#' File format header (big endian, concatenated in order):
#' - Magic bytes (`FWENC1`, 6 bytes) identify Framework-encrypted files
#' - Salt (32 bytes) used for scrypt key derivation
#' - Nonce (24 bytes) for libsodium's AEAD GCM
#' - Reserved flag (1 byte, currently `0x00` for future use)
#' - Followed by ciphertext of variable length
#'
#' @param data Raw vector to encrypt
#' @param password Character string password
#' @return Raw vector with header and encrypted data
#' @keywords internal
.encrypt_with_password <- function(data, password) {
  checkmate::assert_raw(data)
  checkmate::assert_string(password, min.chars = 1)

  # Check sodium available
  if (!requireNamespace("sodium", quietly = TRUE)) {
    stop(
      "Encryption requires the sodium package.\n\n",
      "Install with: install.packages('sodium')"
    )
  }

  # Generate salt for key derivation
  salt <- sodium::random(.SALT_SIZE)

  # Derive encryption key from password
  key <- .derive_key_from_password(password, salt)

  # Generate nonce for encryption
  nonce <- sodium::random(.NONCE_SIZE)

  # Encrypt data
  cipher <- sodium::data_encrypt(data, key, nonce)

  # Build header: [MAGIC][SALT][NONCE][RESERVED]
  reserved <- as.raw(0x00)
  header <- c(.MAGIC_BYTES, salt, nonce, reserved)

  # Return [header][ciphertext]
  c(header, cipher)
}

#' Decrypt data with password
#'
#' Decrypts data encrypted with .encrypt_with_password().
#'
#' @param encrypted_data Raw vector with header and ciphertext
#' @param password Character string password
#' @return Raw vector of decrypted data
#' @keywords internal
.decrypt_with_password <- function(encrypted_data, password) {
  checkmate::assert_raw(encrypted_data)
  checkmate::assert_string(password, min.chars = 1)

  # Check sodium available
  if (!requireNamespace("sodium", quietly = TRUE)) {
    stop(
      "Decryption requires the sodium package.\n\n",
      "Install with: install.packages('sodium')"
    )
  }

  # Validate minimum length
  if (length(encrypted_data) < .HEADER_SIZE) {
    stop("Invalid encrypted file: too short")
  }

  # Check magic bytes
  magic <- encrypted_data[1:.MAGIC_SIZE]
  if (!identical(magic, .MAGIC_BYTES)) {
    stop("Invalid encrypted file: missing or incorrect magic bytes")
  }

  # Extract salt
  salt_start <- .MAGIC_SIZE + 1
  salt_end <- salt_start + .SALT_SIZE - 1
  salt <- encrypted_data[salt_start:salt_end]

  # Extract nonce
  nonce_start <- salt_end + 1
  nonce_end <- nonce_start + .NONCE_SIZE - 1
  nonce <- encrypted_data[nonce_start:nonce_end]

  # Extract ciphertext (skip header)
  cipher <- encrypted_data[(.HEADER_SIZE + 1):length(encrypted_data)]

  # Derive key from password and salt
  key <- .derive_key_from_password(password, salt)

  # Decrypt
  tryCatch(
    sodium::data_decrypt(cipher, key, nonce),
    error = function(e) {
      stop(
        "Failed to decrypt: ", e$message, "\n\n",
        "The password may be incorrect or the file may be corrupted."
      )
    }
  )
}

#' Check if file is encrypted
#'
#' Checks for FWENC1 magic bytes at start of file.
#'
#' @param file_path Path to file
#' @return Logical
#' @keywords internal
.is_encrypted_file <- function(file_path) {
  checkmate::assert_file_exists(file_path)

  # Read first 6 bytes
  con <- file(file_path, "rb")
  on.exit(close(con), add = TRUE)

  magic <- tryCatch(
    readBin(con, "raw", n = .MAGIC_SIZE),
    error = function(e) raw(0)
  )

  # Check magic bytes
  if (length(magic) < .MAGIC_SIZE) {
    return(FALSE)
  }

  identical(magic, .MAGIC_BYTES)
}
