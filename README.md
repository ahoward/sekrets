# Sekrets

Create encrypted config files and eliminate the need to check in unencrypted information, keys, or other sensitive key .

## About

Sekrets is a command line tool to securely manage encrypted files and settings in your rails' applications and git repositories. Check encrypted information into a repository and manage it alongside the rest of the code base.

# RAILS

## Step 1 Add the Sekrets Gem

```
  gem 'sekrets'
```

_Don't forget to bundle install_

## Step 2 Generate a key file
```
  rake sekrets:generate:key
```

If you get an error, try `bundle exec rake sekrets:generate:key`


This will create a '.sekrets.key' file with somthing like;

    b6f3f6fd5a486054e014e3426e84334e


## Step 3 Add the key file to your .gitignore

```
  $ echo .sekrets.key >> .gitignore
```

You should **never** commit the key files

## Step 4 Add your secrets

```
  rake sekrets:generate:editor
```

This creates a sekrets directory with 2 files;

    sekrets/
      ciphertext
      editor

To add secrets run;

```
  $  ./sekrets/editor
```

Running that command will open your text editor. All your secrets will be added, and encrypted in `ciphertext`.

_Save the file and close._

# Review your secrets

## Confirm your secrets are encrypted;

```
  $ cat sekrets/ciphertext
```

## Display your secrets;

```
  $ sekrets read sekrets/ciphertext
```

## Use YAML formats (Preferred)
Format your passwords in yaml.;

```
  # YAML file format

  :api_key: 123thisIsATestKey
  :another_sekret: foobarbaz
```

You can add an additional files of passwords if you want to manage API passwords, separately. However, you only need your original key.

```
$  sekrets edit config/zendesk.yml.enc
```

# Accessing secrets in your application code

## Step 1 Set a variable
```
    settings = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext'))
```

## Step 2 Call variable


```
    config.token = settings[:api_token] #=> 123thisIsATestKey
    config.foo = settings[:another_sekret] #=> foobarbaz
```



Creates a key

### Add private information
#### rake sekrets:generate:editor
Easily add and edit private information

### Configure things... (What things?)
#### rake sekrets:generate:config

# Non-Rails
## create an encrypted config file

  ruby -r yaml -e'puts({:api_key => 1234}.to_yaml)' | sekrets write config/settings.yml.enc --key 42


## Adding files to Git

## commit it

  git add config/settings.yml.enc

## put the decryption key in a file

  echo 42 > .sekrets.key

## ignore this file in git

  echo .sekrets.key >> .gitignore

## you now no longer need to provide the --key argument to commands

  sekrets read config/settings.yml.enc

  sekrets edit config/settings.yml.enc

## make sure this file gets deployed on your server

  echo " require 'sekrets/capistrano' " >> Capfile

unless deploying to heroku

## commit and deploy

  git add config/settings.yml.enc
  git commit -am'encrypted settings yo'
  git pull && git push && cap staging deploy


## Additional Comments
### KEY LOOKUP
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

### KEY DISTRIBUTION
  sekrets does *not* attempt to solve the key distribution problem for you,
  with one exception:

  if you are using capistrano to do a 'vanilla' ssh based deploy a simple
  recipe is provided which will detect a local keyfile and scp it onto the
  remote server(s) on deploy.

  sekrets assumes that the local keyfile, if it exists, is correct.

  in plain english the capistrano recipe does:

    scp ./sekrets.key deploy@remote.host.com:/rails_root/current/sekrets.key

### Be Smart

  The local keyfile should *never* be checked in and also should be in .gitignore

  distribution of this key among developers is outside the scope of the
  library.  encrypted email is likely the best mechanism for distribution,
  but you've still got to sovle this problem for yourself ;-/
