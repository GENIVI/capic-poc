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
import javax.inject.Inject;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.franca.core.dsl.FrancaPersistenceManager;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FModel;

public class Generator {
    private final int MAX_SPACES_PER_TAB = 16;
    private final String SPACES = "                 ";
    private int spacesPerTab = 4;
    @Inject private FrancaPersistenceManager loader;

    protected IFile writeFile(IFileMaker fileMaker, String name, String contents) throws UnsupportedEncodingException
    {
        //FIXME: Make indentation configurable
        if (spacesPerTab >= 0 && spacesPerTab <= MAX_SPACES_PER_TAB) {
            String tabExpansion = SPACES.substring(0, spacesPerTab);
            contents = contents.replaceAll("[\t]", tabExpansion);
        }
        //FIXME: Make output file encoding configurable or use system settings
        InputStream source = new ByteArrayInputStream(contents.getBytes("UTF-8"));
        return fileMaker.makeFile("", name, source);
    }

    public String generate(IFile inFile, IFileMaker fileMaker) {
        URI uri = URI.createFileURI(inFile.getLocation().toString());
        FModel model = loader.loadModel(uri, uri);
        FInterface ifs = model.getInterfaces().get(0);
        XGenerator xgen = new XGenerator();
        try {
            writeFile(fileMaker, "client-" + ifs.getName() + ".h", xgen.generateClientInterfaceHeader(ifs).toString());
            writeFile(fileMaker, "client-" + ifs.getName() + ".c", xgen.generateClientInterfaceBody(ifs).toString());
            writeFile(fileMaker, "server-" + ifs.getName() + ".h", xgen.generateServerInterfaceHeader(ifs).toString());
            writeFile(fileMaker, "server-" + ifs.getName() + ".c", xgen.generateServerInterfaceBody(ifs).toString());
            return "Successfully generated code for " + inFile.getLocation().toPortableString();
        } catch (UnsupportedEncodingException e) {
            return "Failed to decode input string";
        }
    }
}
