import base64
import collections
import json
import os.path
import pickle


class State(object):

    def __init__(self, initial_state, update_func):
        self._state = initial_state
        self._update_func = update_func
        if os.path.isfile('init.txt'):
            with open('init.txt', 'rb') as init_file:
                self._state = pickle.loads(
                    base64.decodebytes(init_file.read()))
                if os.path.isfile('log.txt'):
                    with open('log.txt', 'rb') as log_file:
                        for line in log_file.readlines():
                            if not line:
                                continue
                            msg = pickle.loads(base64.decodebytes(line))
                            self._state = update_func(msg, self._state)
        else:
            with open('init.txt', 'wb') as init_file:
                init_file.write(base64.b64encode(pickle.dumps(self._state)))
        self._log_file = open('log.txt', 'ab')

    def snapshot(self):
        return self._state

    def dispatch(self, msg):
        self._log_file.write(base64.b64encode(pickle.dumps(msg)))
        self._log_file.write(b'\n')
        self._state = self._update_func(msg, self._state)
