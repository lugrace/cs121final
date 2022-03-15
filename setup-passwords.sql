-- [Part E]
-- [Grace Lu - glu@caltech.edu]
-- [Jae Yoon Kim - jaeyoonk@caltech.edu]

-- File for Password Management section of Final Project

-- (Provided) This function generates a specified number of characters for using as a
-- salt in passwords.
DROP FUNCTION IF EXISTS make_salt;
DELIMITER !
CREATE FUNCTION make_salt(num_chars INT) 
RETURNS VARCHAR(20) NOT DETERMINISTIC
BEGIN
    DECLARE salt VARCHAR(20) DEFAULT '';

    -- Don't want to generate more than 20 characters of salt.
    SET num_chars = LEAST(20, num_chars);

    -- Generate the salt!  Characters used are ASCII code 32 (space)
    -- through 126 ('z').
    WHILE num_chars > 0 DO
        SET salt = CONCAT(salt, CHAR(32 + FLOOR(RAND() * 95)));
        SET num_chars = num_chars - 1;
    END WHILE;

    RETURN salt;
END !
DELIMITER ;

-- Provided (you may modify if you choose)
-- This table holds information for authenticating users based on
-- a password.  Passwords are not stored plaintext so that they
-- cannot be used by people that shouldn't have them.
-- You may extend that table to include an is_admin or role attribute if you 
-- have admin or other roles for users in your application 
-- (e.g. store managers, data managers, etc.)
DROP TABLE IF EXISTS user_info;
CREATE TABLE user_info (
    -- Usernames are up to 20 characters.
    username VARCHAR(20) PRIMARY KEY,

    -- Salt will be 8 characters all the time, so we can make this 8.
    salt CHAR(8) NOT NULL,

    -- We use SHA-2 with 256-bit hashes.  MySQL returns the hash
    -- value as a hexadecimal string, which means that each byte is
    -- represented as 2 characters.  Thus, 256 / 8 * 2 = 64.
    -- We can use BINARY or CHAR here; BINARY simply has a different
    -- definition for comparison/sorting than CHAR.
    password_hash BINARY(64) NOT NULL,
    
    -- is_admin is a bool variable that defaults to not an admin
    -- an admin will have much higher level access than clients
    -- admin can have access over all functionality as well as
    -- updating/deleting privileges
    -- clients can only view.
    is_admin TINYINT NOT NULL DEFAULT 0
);

-- [Problem 1a]
-- Adds a new user to the user_info table, using the specified password (max
-- of 20 characters). Salts the password with a newly-generated salt value,
-- and then the salt and hash values are both stored in the table.
DROP PROCEDURE IF EXISTS sp_add_user;
DELIMITER !
CREATE PROCEDURE sp_add_user(new_username VARCHAR(20), password VARCHAR(20))
BEGIN
    DECLARE salt CHAR(8);
    DECLARE hashish BINARY(64);
    SET salt = make_salt(8);
    SET hashish = UNHEX(SHA2(CONCAT(`password`, salt), 256));
    
    INSERT INTO user_info VALUES (new_username, salt, hashish, 0);
END !
DELIMITER ;

-- [Problem 1b]
-- Authenticates the specified username and password against the data
-- in the user_info table.  Returns 1 if the user appears in the table, and the
-- specified password hashes to the value for the user. Otherwise returns 0.
DROP FUNCTION IF EXISTS authenticate;
DELIMITER !
CREATE FUNCTION authenticate(username VARCHAR(20), password VARCHAR(20))
RETURNS TINYINT DETERMINISTIC
BEGIN
    DECLARE salty CHAR(8);
    DECLARE hashish BINARY(64);
    DECLARE input_hash BINARY(64);
    -- check if the username is in there
    IF ((SELECT COUNT(*) 
        FROM user_info
        WHERE username = user_info.username) = 1) THEN
        
        
        SET salty = (SELECT salt FROM user_info
            WHERE username = user_info.username);
        SET hashish = (SELECT password_hash FROM user_info
            WHERE username = user_info.username);
        SET input_hash = UNHEX(SHA2(CONCAT(`password`, salty), 256));
        -- check if the password matches
        IF (hashish = input_hash) THEN
            RETURN 1;
        END IF;
    END IF;
    RETURN 0;
  -- TODO
END !
DELIMITER ;

-- [Problem 1c]
-- Add at least two users into your user_info table so that when we run this file,
-- we will have examples users in the database.
CALL sp_add_user('barackobama', 'BarackIsTheBest');
CALL sp_add_user('rosenbaum', 'CIT4Lyfe');

SELECT authenticate('rosenbaum', 'CIT4Lyfe');
SELECT authenticate('barackobama', 'BarackIsTheBest');
SELECT authenticate('barackobama', 'Russianhacker');
SELECT authenticate('tester', 'Russianhacker');


-- [Adding admins]
DROP PROCEDURE IF EXISTS sp_give_admin;
DELIMITER !
CREATE PROCEDURE sp_give_admin(inp_username VARCHAR(20))
BEGIN
    UPDATE user_info 
    SET is_admin = 1
    WHERE username = inp_username;
END !
DELIMITER ;
-- admin
CALL sp_add_user('a', 'aa');
CALL sp_give_admin('a');
-- client
CALL sp_add_user('c', 'cc');

-- [Checking if they are admin]

DROP FUNCTION IF EXISTS check_admin;
DELIMITER !
CREATE FUNCTION check_admin(inp_username VARCHAR(20))
RETURNS TINYINT DETERMINISTIC
BEGIN
    -- check if the username is in there
    IF ((SELECT COUNT(*) 
        FROM user_info
        WHERE inp_username = user_info.username) = 1) THEN
        
        RETURN (SELECT is_admin 
            FROM user_info 
            WHERE username = inp_username);
    END IF;
    RETURN 0;
    
END !
DELIMITER ;


SELECT check_admin('a');
SELECT check_admin('c');



-- [Problem 1d]
-- Optional: Create a procedure sp_change_password to generate a new salt and change the given
-- user's password to the given password (after salting and hashing)
DROP PROCEDURE IF EXISTS sp_change_password;
DELIMITER !
CREATE PROCEDURE sp_change_password(input_username VARCHAR(20), new_password VARCHAR(20))
BEGIN
    DECLARE salty CHAR(8);
    DECLARE hashish BINARY(64);
    SET salty = make_salt(8);
    SET hashish = (SELECT UNHEX(SHA2(CONCAT(new_password, salty), 256)));
    
    UPDATE user_info 
    SET salt = salty, password_hash = hashish
    WHERE username = input_username;
END !
DELIMITER ;



