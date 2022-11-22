_Usage_:
select the saver with rendered prores version, and run the script

_Dependencies_:

* ftrack-python-api (installed automatically)
* python3.6+

There should be a few environment variables set:

* `FTRACK_API_KEY` = generate one in your ftrack account settings or use a global API
* `FTRACK_API_USER` = your-ftrack-email
* `FTRACK_SERVER` = your ftrack project url

It will parse the comp name, find the corresponding ftrack task and upload the version there. 
