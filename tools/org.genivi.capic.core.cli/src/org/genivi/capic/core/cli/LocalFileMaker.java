/* SPDX license identifier: EPL-1.0
 * Copyright (C) 2015, Visteon Corp.
 *
 * This file is part of Common API C
 *
 * This program and the accompanying materials are made available
 * under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html.
 * For further information see http://www.genivi.org/.
 *
 * Contributors:
 *   Pavel Konopelko, pkonopel@visteon.com
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
            if (!folder.exists()) {
                folder.createLink(
                        new Path(fullPathName),
                        IResource.FORCE | IResource.DERIVED | IResource.ALLOW_MISSING_LOCAL, null);
            }
            IFile file = folder.getFile(fileName);
            if (file.exists())
                file.delete(IResource.FORCE, null);
            file.createLink(
                    new Path(fullPathName + File.separator + fileName),
                    IResource.FORCE | IResource.DERIVED | IResource.ALLOW_MISSING_LOCAL, null);
            file.setContents(source, IResource.FORCE, null);
            return file;
        } catch (CoreException e) {
            //FIXME: re-throw
            System.out.println("Unable to link output folder or file: " + e.getMessage());
            return null;
        }
    }
}
