<?php
/** DB Info */
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');
/** MySQL database username */
define('DB_USER', 'root');
/** MySQL database password */
define('DB_PASSWORD', 'wordpress');
/** MySQL hostname */
if (php_sapi_name() == "cli") {
	define('DB_HOST', '127.0.0.1:8003');
} else {
	define('DB_HOST', 'db');
}
/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');
/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/** Auth Filler */
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if (!defined('ABSPATH'))
  define('ABSPATH', dirname(__FILE__) . '/wordpress');

if (php_sapi_name() == "cli") {
	define('WP_HOME', 'http://localhost:8001');
} else {
	define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST']);
}
define('WP_SITEURL', WP_HOME . '/wordpress');
define('WP_CONTENT_DIR', realpath(ABSPATH . '../wp-content'));
define('WP_CONTENT_URL', WP_HOME . '/wp-content');
//define('WP_TEMP_DIR', realpath(ABSPATH . '../../tmp/'));

define('FS_METHOD', 'direct');

define('FORCE_SSL_ADMIN', false);
define('FORCE_SSL_LOGIN', false);

define('WP_CACHE', false);

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
