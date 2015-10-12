/* SPDX license identifier: MPL-2.0
 * Copyright (C) 2015, Visteon Corp.
 * Author: Pavel Konopelko, pkonopel@visteon.com
 *
 * This file is part of Common API C
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License (MPL), version 2.0.
 * If a copy of the MPL was not distributed with this file,
 * you can obtain one at http://mozilla.org/MPL/2.0/.
 * For further information see http://www.genivi.org/.
 */
package org.genivi.capic.core;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;

import org.eclipse.core.resources.IFile;

public class Generator {
    private IFile inFile;
    private IFileMaker fileMaker;

    public Generator(IFile inFile, IFileMaker fileMaker) {
        this.inFile = inFile;
        this.fileMaker = fileMaker;
    }

    public String generate() {
        String dummy = "#include <stdio.h>\nint main(int argc, char *argv[]) {\n  return 0;\n}\n";
        try {
            InputStream source = new ByteArrayInputStream(dummy.getBytes("UTF-8"));
            IFile outFile = fileMaker.makeFile("", "test.c", source);
            return inFile.getLocation().toPortableString() + "\n"
                    + outFile.getLocation().toPortableString();
        } catch (UnsupportedEncodingException e) {
            return "Failed to decode input string";
        }
    }
}
