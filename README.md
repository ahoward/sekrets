![](header.jpg)

Stop checking in unencrypted information.

## About

Sekrets is a command line tool to create and manage encrypted files.

## Purpose

Check encrypted information into a repository and manage it alongside the rest of the code base.

# Using with RAILS

## Setup

### (Step 1) Add the Sekrets Gem

```
  gem 'sekrets'
```

_Don't forget to bundle install_

## File Creation

### (Step 2) Generate a key file
```
  rake sekrets:generate:key
```

If you get an error, try `bundle exec rake sekrets:generate:key`

This will create a '.sekrets.key' file with something like;

    b6f3f6fd5a486054e014e3426e84334e


### (Step 3) Add .key to .gitignore

```
  $ echo .sekrets.key >> .gitignore
```

You should **never** commit .key files

### (Step 4) Generate a file to holds secrets

```
  rake sekrets:generate:editor
```

This creates a sekrets directory with 2 files;

    sekrets/
      ciphertext
      editor

#### Add secrets to file by running

```
  $  ./sekrets/editor
```

That will opens your text editor. All your secrets will be added, and encrypted in `ciphertext`.

#### Use YAML formats (Preferred)
Format your passwords in yaml.;

```
  # YAML file format
  # Example uses...
  :api_key: 123thisIsATestKey
  :another_sekret: foobarbaz
```

_Save the file and close._

## Review your secrets

### Confirm your secrets are encrypted

```
  $ cat sekrets/ciphertext
```

### Display your secrets;

```
  $ sekrets read sekrets/ciphertext
```

Notice start with keyword `sekrets`

## Having multiple Sekret files
You can add additional files of passwords if you want to manage API passwords, separately.

_You only need your single original `.sekrets.key' file._

```
$  sekrets edit config/zendesk.yml.enc
```
Creates a new encrypted file called 'zendesk.yml.enc'

## Assigning secrets to variables
Now that you have files encrypted, here's how to access them in Rails.

### (Step 1) Set secrets to a variable
```
    settings = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext')) # First File

    zendesk_secrets = Sekrets.settings_for(Rails.root.join('config', 'zendesk')) # zendesk File
```


### (Step 2) Calling a particular secret
Now that you have the variable, you can use it with whatever content you need (YAML Format example here)

```
    settings[:api_key] #=> 123thisIsATestKey
```

#### Then, set values with your variables

```
    config.token = settings[:api_key]
```

# Using without Rails
Sekrets can be used in non-rails apps.

## (Step 1) Create both key and encrypted file

```
  ruby -r yaml -e'puts({:api_key => 1234}.to_yaml)' | sekrets write config/settings.yml.enc --key 42 # key can be called whatever you want it to be. ('42' is placeholder)
```

## (Step 2) Put the decryption key in a file

```
  echo 42 > .sekrets.key
```

### You now no longer need to provide the --key argument to commands

```
  sekrets read config/settings.yml.enc
  sekrets edit config/settings.yml.enc
```

After you add your key to `.sekrets.key', all sekret files will access the key.

# Additional Comments

## If using Capistrano

_Not necessary for heroku_

Make sure this file gets deployed on your server

  echo " require 'sekrets/capistrano' " >> Capfile

## KEY LOOKUP
for *all* operations, from the command line or otherwise, sekrets uses the
following algorithm to search for a decryption key:

- any key passed directly as a parameter to a library call will be preferred

- otherwise the code looks for a companion key file.  for example, given the
  file 'config/sekrets.yml.enc' sekrets will look for a key at

    config/.sekrets.yml.enc.key

  if either of these is found to be non-empty the contents of the file will
  be used as the decryption key for that file.  you should *never* commit
  these key files and also add them to your .gitignore - or similar.

- next a project key file is looked for.  the path of this file is

    ./.sekrets.key

  normally and, in a rails' application

    RAILS_ROOT/.sekrets.key

- if that is not found sekrets looks for the key in the environment under
  the env var

    SEKRETS_KEY

  the env var used is configurable in the library

- next the global key file is search for, the path of this file is

    ~/.sekrets.key

- finally, if no key has yet been specified or found, the user is prompted
  to input the key.  prompt only occurs if the user us attached to a tty.
  so, for example, no prompt will hang and application being started in the
  background such as a rails' application being managed by passenger.


see Sekrets.key_for for more details

## KEY DISTRIBUTION
  sekrets does *not* attempt to solve the key distribution problem for you,
  with one exception:

  if you are using capistrano to do a 'vanilla' ssh based deploy a simple
  recipe is provided which will detect a local keyfile and scp it onto the
  remote server(s) on deploy.

  sekrets assumes that the local keyfile, if it exists, is correct.

  in plain English the capistrano recipe does:

    scp ./sekrets.key deploy@remote.host.com:/rails_root/current/sekrets.key

## Be Smart

  The local key file should *never* be checked in and also should be in .gitignore

  distribution of this key among developers is outside the scope of the
  library.  encrypted email is likely the best mechanism for distribution,
  but you've still got to solve this problem for yourself ;-/


## TODO: Document Configure

```
 rake sekrets:generate:config
```
