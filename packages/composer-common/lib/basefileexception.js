/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const BaseException = require('./baseexception');

/**
 * Exception throws when a composer file is semantically invalid
 * @extends BaseException
 * @see See {@link BaseException}
 * @class
 * @memberof module:composer-common
 * @public
 */
class BaseFileException extends BaseException {

    /**
     * Create an IllegalModelException
     * @param {string} message - the message for the exception
     * @param {string} fileLocation - the optional file location associated with the exception
     * @param {string} fullMessage - the optional full message text
     */
    constructor(message, fileLocation, fullMessage) {
        super(fullMessage ? fullMessage : message);
        this.fileLocation = fileLocation;
        this.shortMessage = message;
    }

    /**
     * Returns the file location associated with the exception or null
     * @return {string} the optional location associated with the exception
     */
    getFileLocation() {
        return this.fileLocation;
    }

    /**
     * Returns the error message without the location of the error
     * @returns {string} the error message
     */
    getShortMessage() {
        return this.shortMessage;
    }
}

module.exports = BaseFileException;