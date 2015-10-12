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
package org.genivi.capic.core.cli;

import java.io.File;
import java.io.InputStream;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.Path;
import org.genivi.capic.core.IFileMaker;

public class LocalFileMaker implements IFileMaker {
    private IProject parent;
    private String prefixPathName;

    public LocalFileMaker(IProject parent) {
        this.parent = parent;
        File workingDirectory = new File(".");
        prefixPathName = workingDirectory.getAbsolutePath();
        // Remove trailing dot
        prefixPathName = prefixPathName.substring(0, prefixPathName.length() - 1);
        prefixPathName = prefixPathName + File.separator + SRCGEN_FOLDER;
    }

    public IFile makeFile(String pathName, String fileName, InputStream source) {
        String fullPathName = prefixPathName + File.separator + pathName;
        try {
            if (!parent.isOpen())
                parent.open(null);
            IFolder folder = parent.getFolder(SRCGEN_FOLDER);
            folder.createLink(
                    new Path(fullPathName),
                    IResource.FORCE | IResource.DERIVED | IResource.ALLOW_MISSING_LOCAL, null);
            IFile file = folder.getFile(fileName);
            if (file.exists())
                file.delete(IResource.FORCE, null);
            file.createLink(
                    new Path(fullPathName + File.separator + fileName),
                    IResource.FORCE | IResource.DERIVED | IResource.ALLOW_MISSING_LOCAL, null);
            file.setContents(source, IResource.FORCE, null);
            return file;
        } catch (CoreException e) {
            System.out.println("Unable to link output folder or file: " + e.getMessage());
            return null;
        }
    }
}
