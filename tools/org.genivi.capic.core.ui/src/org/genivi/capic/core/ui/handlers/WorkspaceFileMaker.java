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
package org.genivi.capic.core.ui.handlers;

import java.io.InputStream;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.Path;
import org.genivi.capic.core.IFileMaker;

public class WorkspaceFileMaker implements IFileMaker {
    private IProject parent;

    public WorkspaceFileMaker(IProject parent) {
        this.parent = parent;
    }

    public IFile makeFile(String pathName, String fileName, InputStream source) {
        //FIXME: recursively create nested folders under OUT_FOLDER
        //String targetFolderName = OUT_FOLDER + Path.SEPARATOR + pathName;
        String targetFolderName = SRCGEN_FOLDER;
        try {
            if (!parent.isOpen())
                parent.open(null);
            Path folderPath = new Path(targetFolderName);
            IFolder folder = parent.getFolder(folderPath);
            if (!folder.exists())
                folder.create(IResource.FORCE | IResource.DERIVED, false, null);
            IFile file = folder.getFile(fileName);
            if (file.exists())
                file.delete(IResource.FORCE, null);
            file.create(source, IResource.FORCE, null);
            return file;

        } catch (CoreException e) {
            //FIXME: re-throw
            System.out.println("Unable to crate output folder or file: " + e.getMessage());
            return null;
        }
    }
}
