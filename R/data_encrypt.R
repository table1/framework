#' Encrypt data using sodium
#' @param value Data to encrypt
#' @param key Encryption key
#' @return Encrypted data as raw
#' @keywords internal
.encrypt_data <- function(value, key) {
  # Convert data to raw if not already
  if (!is.raw(value)) {
    value <- serialize(value, NULL)
  }

  # Generate nonce
  nonce <- sodium::random(24)

  # Encrypt
  cipher <- sodium::data_encrypt(value, key, nonce)

  # Combine nonce and cipher
  c(nonce, cipher)
}

#' Decrypt data using sodium
#' @param encrypted_data Encrypted data as raw
#' @param key Encryption key
#' @return Decrypted data
#' @keywords internal
.decrypt_data <- function(encrypted_data, key) {
  # Split nonce and cipher
  nonce <- encrypted_data[1:24]
  cipher <- encrypted_data[25:length(encrypted_data)]

  # Decrypt
  value <- sodium::data_decrypt(cipher, key, nonce)

  # Unserialize if needed
  tryCatch(
    unserialize(value),
    error = function(e) value
  )
}
