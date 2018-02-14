<?xml version="1.0" encoding="UTF-8"?>
<!-- 
	Copyright © Nictiz
	see https://www.nictiz.nl/

    This file is part of Medicatieviewer
	
	This program is free software; you can redistribute it and/or modify it under the terms of the
	GNU Lesser General Public License as published by the Free Software Foundation; either version
	3.0 of the License, or (at your option) any later version.
	
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU Lesser General Public License for more details.
	
	The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:hl7="urn:hl7-org:v3" 
    xmlns:hl7nl="urn:hl7-nl:v3" 
    xmlns:util="urn:hl7:utilities"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nf="http://www.nictiz.nl/functions" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xd hl7 xsi xhtml" xpath-default-namespace="urn:hl7-org:v3" version="2.0">
    <xsl:import href="BuildHeader.xsl"/>
    <xsl:import href="BuildGeneral.xsl"/>
    <xsl:import href="nictizFunctions.xsl"/>
    <xd:doc>
        <xd:desc>
            <xd:p>Use XHTML 1.0 Strict with UTF-8 encoding. CDAr3 specifies an XHTML subset of tags in Section.text so that makes mapping easier.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output indent="yes" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>
    <!-- 
  <xsl:comment>Voor XSD schema validatie in XSL is Saxon-EE benodigd. Die is niet beschikbaar in Art-Decor,
    maar wel in oXygen, dus onderstaande regel kan geactiveerd worden tijdens ontwikkeling, maar moet bij deployment
    uitgecommentarieerd staan.</xsl:comment>
  <xsl:import-schema namespace="urn:hl7-org:v3"
    schema-location="mp-xml-20161114T174207/schemas_codegen/CDANL_extended.xsd"/>
-->
    <!-- Enumeration of 'Constants' for the different Block Types ('bouwsteen types'):
       ma = 'medicatie afspraak'       
       ta = 'toedienings afspraak'       
       gb = 'medicatiegebruik'
       (currently the viewer doesn't support the 'toediening' block type) 
       supply = contains logistics information, that is not the focus of this viewer        
  -->
    <xsl:variable name="BT_UNKNOWN" select="0" as="xs:decimal"/>
    <xsl:variable name="BT_MA" select="1" as="xs:decimal"/>
    <xsl:variable name="BT_TA" select="2" as="xs:decimal"/>
    <xsl:variable name="BT_GB" select="3" as="xs:decimal"/>
    <xsl:variable name="BT_SUPPLY" select="10" as="xs:decimal"/>
    <!-- Enumeration of 'Constants' for the different tables, signifying whether the 'MBH' 
       has recently stopped being active, is currently active, or will become active in the near future.
       MBH's that are too far in the past or in the future are not displayed and get table NONE.
  -->
    <xsl:variable name="TABLE_NONE" select="0" as="xs:decimal"/>
    <xsl:variable name="TABLE_PAST" select="1" as="xs:decimal"/>
    <xsl:variable name="TABLE_CURRENT" select="2" as="xs:decimal"/>
    <xsl:variable name="TABLE_FUTURE" select="3" as="xs:decimal"/>
    <!-- Binary data of the 3 icons for the block types. In Art-Decor it won't work to just load icons from the current folder,
    and the method that works for Art-Decor doesn't work when the transformation is done locally in oXygen (I suspect).
    Including the icon data makes the resulting html larger, but at least works in both cases.
  -->
    <xsl:variable name="ImagedataIconZorgverlener"
        select="'data:image/gif;base64,R0lGODlhDQATAPcAAN81N/Gdn+dpa/fPz+uDg+FRU/O5u+l3eedDQ/3x8e2TlfGvr98/QedxceuJifnd3fOnp+l9f+85O+uHh+lfX/fHyf35+euFh+dXWel1dffV1eFLTfGhoedtbeuFhfXBwel7e/nl5fGpq+mBgfs7Pf/9/d87Pe+fn/nT1eFHSfOXl/O1tf89P+lzdfGpqetbW+k3OfvR0euDheVTVfW9ve15ef339/Wxs+FBQ+1zc+uNj/vh4fenqfnNzf/7++91d+dvcemBg/07P++foedrbffP0edRU/O7u+93ee1FR/3z8+2VlfOvr+s9P+lxc/vf3/Gnqel/gfM5O+2Hh+VlZ/fJy//5+e+Fh+lXWel1d/nX1+NNT+ttb+2FhfXDw/F7ffvn5/07Pf///+dHSe+Zme9bW+s3O+2Dhe2Nj+uBg/GfoQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAANABMABwi8AMUIfFDEh0CBJQQmOFEDQ4MZBKIAOQDBhhglUH4YIQLDxJYNAFhQsXCwxw0tKHaISZCGRJWDByMKHCJkwMEQPFzIiEKGAokGCcXQaEIiw4Q0HcqcsCLQAoMXT8S0mABToBUTRBL4MPAhKMwVEjqmYIDjjEWYKJZciBAkiwQFVQ96WCBGR4G4Dz50mABlDFyYBpIEcVJDAIe4KSBIpRtXTBoMAXQEqGAw7o0rF9IgodFY4AEvYio3HgCmakAAOw=='"/>
    <xsl:variable name="ImagedataIconApotheker"
        select="'data:image/gif;base64,R0lGODlhEwATAPcAACkpKZeXl1tbW8/Pz0NDQ+np6XV1dTc3N2lpaU9PT/X19bOzs93d3WNjY4ODgzExMUlJSe/v7z09PVVVVfv7+729vaWlpW9vb+Pj419fX9nZ2Xt7e7m5uS0tLUdHR+3t7Ts7O1NTU/n5+WdnZ4uLizU1NU1NTfPz80FBQVlZWf///62trXNzc+fn539/f5ubm11dXdPT00VFRevr6zk5OW1tbVFRUff397e3t+Hh4WVlZYWFhTMzM0tLS/Hx8T8/P1dXV/39/cPDw6mpqXFxceXl5WFhYdvb2319fbu7uy8vLwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAATABMABwjyAFUIHEiwoIggBRMWHCCgxgyFClckkMFjCESCPkgQMCGhQYuLAjVcSJCARoaHAxEWxAHDRoIDMD6AVBAggQ0IHTKIKFgAxwIOFXC48ABBggQlFyz4IJjkgIcLDoh4KKEEwAEUNA4wICjEgw0YOoxAAPGgw4MSNAjkIBgjRQojCIwkIACiBFoaCSIQjMBCQIa4CTz8AEGDMIKEL4AIgCHAhAyjIH4osZCwyAUgKSb08ECAAFYYJxQeYZECAgEZKH7Q6IHhogMgNWDIAFHXyEUFMHps0AFCiRIeEopAPIEEBpIGNIAnICLzoggfH1oUiEBBYUAAOw=='"/>
    <xsl:variable name="ImagedataIconPatient"
        select="'data:image/gif;base64,R0lGODlhEwATAPcAADGJx53F42ep20eZ1dnn8z2RzTOR1e/1+bfV6T+V1TGNz1Wd0a/P5/f7/TGNzePv9zGJy0mXzcff8TWV2Ye74UOTzZvJ6fP5+73Z7WOl0zmX2S+JyTmZ3zmT0TWT2evz+aHH49vr9TuT1bXV7U+d17PT6f///5vD4Z3H5XWv2TWT1fH3+7fV6/v9/efx9zGLyzmV2Y293/f5/TeX2zOJyT2b3z2T0d/t9zOJx5nF5U2d1T+Rze/1+z2X1zGP01mf0bHR6ePv+cnh8TeV2Ym74UWTzaXL5/f5+8Pb7Vmj2TGJyTmZ4TuT0e3z+VWf1a/T632z2TOT17nV6/39/TGLzTmX2+Ht9wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAATABMABwjPAE0IHEiwoMGDCBPKkDBCyJGEBIHo8ECRhBSIJhjUoKIEAAAINRAkPLADAg4ANAAogVBkBUIEEzymRAnAAwaEATzg6JgSBw4PRhAy0KDy5M6aIg8+YAIBwNGPBT4kPLFkg8ePHEBgzJFghocZTAJAvHDDxAcgFoDwMBFkykECSRIQsSJwSggKCQS4KGhlgAIlBphEWBChgwHAJFwOzGCgqBIqkDt6nABlIBKiTj2evOpRSYcQAlMY2MxZ81UPMUy0KEKFBg4asGPPdK3gh4mAADs='"/>
    <!-- debugMessages = true means debug information is shown/logged to the message window -->
    <xsl:variable name="debugMessages" as="xs:boolean" select="true()"/>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="/">
        <xsl:comment> Do NOT edit this HTML directly: it was generated via an XSLT transformation from a HL7 v3 CDA document. </xsl:comment>
        
        <xsl:choose>
            <xsl:when test="hl7:MCCI_IN200101">
                <xsl:apply-templates select="hl7:MCCI_IN200101"/>
            </xsl:when>
            <xsl:when test="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:ClinicalDocument">
                <xsl:apply-templates select="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:ClinicalDocument">
                    <xsl:with-param name="doHeader" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:organizer">
                <xsl:apply-templates select="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:organizer">
                    <xsl:with-param name="doHeader" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="hl7:ClinicalDocument">
                <xsl:apply-templates select="hl7:ClinicalDocument">
                    <xsl:with-param name="doHeader" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="hl7:organizer">
                <xsl:apply-templates select="hl7:organizer">
                    <xsl:with-param name="doHeader" select="true()"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Element not supported <xsl:value-of select="name()"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="hl7:MCCI_IN200101">
        <html>
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <title>Medicatie overzicht MP9 (batch)</title>
                <!--<link rel="stylesheet" href="medviewer9.css" type="text/css" media="screen" charset="utf-8"/>-->
                <style type="text/css"><xsl:copy-of select="replace(unparsed-text('MedViewer9.css'),'\r','')"/></style>
            </head>
            <body>
                <xsl:choose>
                    <xsl:when test="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:ClinicalDocument">
                        <xsl:apply-templates select="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:ClinicalDocument">
                            <xsl:with-param name="doHeader" select="false()"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:organizer">
                        <xsl:apply-templates select="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:organizer">
                            <xsl:with-param name="doHeader" select="false()"/>
                        </xsl:apply-templates>
                    </xsl:when>
                </xsl:choose>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="hl7:ClinicalDocument | hl7:organizer">
        <xsl:param name="doHeader" as="xs:boolean" required="yes"/>
        
        <xsl:choose>
            <xsl:when test="$doHeader">
                <html>
                    <head>
                        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                        <title>Medicatie overzicht MP9</title>
                        <!--<link rel="stylesheet" href="medviewer9.css" type="text/css" media="screen" charset="utf-8"/>-->
                        <style type="text/css"><xsl:copy-of select="replace(unparsed-text('MedViewer9.css'),'\r','')"/></style>
                    </head>
                    <body>
                        <xsl:apply-templates select="." mode="doContent"/>
                    </body>
                </html>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="doContent"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="hl7:ClinicalDocument | hl7:organizer" mode="doContent">
        
        <!-- uncomment the next line to execute a unit test on the date(Time) conversion functions. -->
        <!--<xsl:call-template name="testConvertDateTime"/>-->
        <!-- header section -->
        <xsl:call-template name="buildHeader">
            <xsl:with-param name="authorElement" select="hl7:author"/>
        </xsl:call-template>
        <!-- section 'algemeen' -->
        <xsl:call-template name="buildGeneral"/>
        <!-- Create a group per MBH based on the MHB id, with parameters for startDate and target table -->
        <xsl:variable name="mp" select="."/>
        <xsl:variable name="index" as="element()*">
            <xsl:for-each-group select="//*[hl7:templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]" group-by="hl7:id/concat(@root, @extension)">
                <xsl:variable name="mbhStartDate" as="xs:dateTime" select="nf:determineMBHstartDate(current-group())"/>
                <xsl:variable name="mbhTable" as="xs:decimal" select="nf:determineMBHtable(current-group(), $mbhStartDate)"/>
                <mb id="{current-grouping-key()}" startdatum="{$mbhStartDate}" table="{$mbhTable}"/>
            </xsl:for-each-group>
        </xsl:variable>
        <!-- Loop over all MBS's, reverse sorted by start date and display each building block -->
        <!-- First the MBH's that are currently active -->
        <h3 class="current">
            <xsl:value-of select="nf:getLocalizedString('currentMedication')"/>
        </h3>
        <table border="1">
            <xsl:call-template name="createTableHeader">
                <xsl:with-param name="tableType" select="$TABLE_CURRENT"/>
            </xsl:call-template>
            <xsl:for-each select="$index">
                <xsl:sort select="@startdatum" order="descending"/>
                <xsl:if test="@table = $TABLE_CURRENT">
                    <xsl:call-template name="createTable">
                        <xsl:with-param name="mp" select="$mp"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </table>
        <!-- Then the MBH's that will become active soon -->
        <h3 class="future">
            <xsl:value-of select="nf:getLocalizedString('futureMedication')"/>
        </h3>
        <table border="1">
            <xsl:call-template name="createTableHeader">
                <xsl:with-param name="tableType" select="$TABLE_FUTURE"/>
            </xsl:call-template>
            <xsl:for-each select="$index">
                <xsl:sort select="@startdatum" order="descending"/>
                <xsl:if test="@table = $TABLE_FUTURE">
                    <xsl:call-template name="createTable">
                        <xsl:with-param name="mp" select="$mp"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </table>
        <!-- And finally the MBH's that have recently become inactive -->
        <h3 class="past">
            <xsl:value-of select="nf:getLocalizedString('recentlyTerminatedMedication')"/>
        </h3>
        <table border="1">
            <xsl:call-template name="createTableHeader">
                <xsl:with-param name="tableType" select="$TABLE_PAST"/>
            </xsl:call-template>
            <xsl:for-each select="$index">
                <xsl:sort select="@startdatum" order="descending"/>
                <xsl:if test="@table = $TABLE_PAST">
                    <xsl:call-template name="createTable">
                        <xsl:with-param name="mp" select="$mp"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </table>
    </xsl:template>
    
    <xd:doc>
        <xd:desc/>
        <xd:param name="curGroup"/>
    </xd:doc>
    <xsl:function name="nf:determineMBHstartDate" as="xs:dateTime">
        <xsl:param name="curGroup" as="node()*"/>
        <xsl:variable name="startDate" select="$curGroup/../../*:effectiveTime/*:low/@value"/>
        <xsl:variable name="registerDate" select="$curGroup/../../*:author/*:time/@value"/>
        <xsl:variable name="mbhStartDates" as="xs:dateTime*">
            <xsl:choose>
                <xsl:when test="$startDate">
                    <xsl:for-each select="$startDate">
                        <xsl:value-of select="nf:convertDateTime(.)"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$registerDate">
                        <xsl:value-of select="nf:convertDateTime(.)"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="min($mbhStartDates)"/>
    </xsl:function>
    <xd:doc>
        <xd:desc/>
        <xd:param name="curGroup"/>
        <xd:param name="mbhStartDate"/>
    </xd:doc>
    <xsl:function name="nf:determineMBHtable" as="xs:decimal">
        <xsl:param name="curGroup" as="item()*"/>
        <xsl:param name="mbhStartDate" as="xs:dateTime"/>
        <xsl:variable name="stopDate" select="nf:convertDateTime($curGroup/../../*:effectiveTime/*:high/@value)" as="xs:dateTime"/>
        <xsl:choose>
            <!-- if stop is more than 3 months before now: don't show -->
            <xsl:when test="
                    $stopDate ne $nfInvalidDateTime and
                    $stopDate &lt; current-dateTime() - xs:yearMonthDuration('P3M')">
                <xsl:value-of select="$TABLE_NONE"/>
            </xsl:when>
            <!-- if stop is before now but less than 3 months before now: show as recently stopped -->
            <xsl:when test="
                    $stopDate ne $nfInvalidDateTime and
                    $stopDate &lt; current-dateTime() and
                    $stopDate > current-dateTime() - xs:yearMonthDuration('P3M')">
                <xsl:value-of select="$TABLE_PAST"/>
            </xsl:when>
            <!-- if start is more than 2 months after now: don't show -->
            <xsl:when test="
                    $mbhStartDate ne $nfInvalidDateTime and
                    $mbhStartDate > current-dateTime() + xs:yearMonthDuration('P2M')">
                <xsl:value-of select="$TABLE_NONE"/>
            </xsl:when>
            <!-- if start is later than now but less than 2 months after now: show as future -->
            <xsl:when test="
                    $mbhStartDate ne $nfInvalidDateTime and
                    $mbhStartDate > current-dateTime() and
                    $mbhStartDate &lt; current-dateTime() + xs:yearMonthDuration('P2M')">
                <xsl:value-of select="$TABLE_FUTURE"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$TABLE_CURRENT"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xd:doc>
        <xd:desc/>
        <xd:param name="tableType"/>
    </xd:doc>
    <xsl:template name="createTableHeader">
        <xsl:param name="tableType" as="xs:decimal"/>
        <tr>
            <th>
                <xsl:value-of select="nf:getLocalizedString('type')"/>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('medication')"/>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('startDate')"/>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('endDate')"/> / <xsl:value-of select="nf:getLocalizedString('duration')"/>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('dosage')"/>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('route')"/>
            </th>
            <th>
                <xsl:choose>
                    <xsl:when test="$tableType eq $TABLE_PAST">
                        <xsl:value-of select="nf:getLocalizedString('abortReason')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="nf:getLocalizedString('prescriptionReason')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('remark')"/>
            </th>
            <th>
                <xsl:value-of select="nf:getLocalizedString('source')"/>
            </th>
        </tr>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
        <xd:param name="mp"/>
    </xd:doc>
    <xsl:template name="createTable">
        <xsl:param name="mp"/>
        <xsl:variable name="mbId" select="@id"/>
        <xsl:variable name="mbContent" select="$mp//*[*/*[hl7:id/concat(@root, @extension) = $mbId]]"/>
        <xsl:if test="$debugMessages">
            <tr bgcolor="#EEEEEE">
                <td>MB</td>
                <td>
                    <xsl:value-of select="@id"/>
                </td>
                <td>
                    <xsl:value-of select="@startdatum"/>
                </td>
                <td>
                    <xsl:value-of select="@table"/>
                </td>
            </tr>
        </xsl:if>
        <xsl:apply-templates select="$mbContent/parent::hl7:entry | $mbContent/parent::hl7:component"/>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="//hl7:entry | //hl7:component">
        <tr>
            <td>
                <!-- type bouwsteen -->
                <xsl:variable name="blockType" select="nf:determineBlockType(.)"/>
                <xsl:call-template name="getBlockTypeIcon">
                    <xsl:with-param name="blockType" select="$blockType"/>
                </xsl:call-template>
            </td>
            <td>
                <xsl:call-template name="getMedicationName"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationStartDate"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationEndDateOrDuration"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationDosage"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationRoute"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationReason"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationRemark"/>
            </td>
            <td>
                <xsl:call-template name="getMedicationAuthor"/>
            </td>
        </tr>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
        <xd:param name="nodes"/>
    </xd:doc>
    <xsl:function name="nf:determineBlockType" as="xs:decimal">
        <xsl:param name="nodes"/>
        <xsl:variable name="blockType">
            <xsl:choose>
                <!--/cda:organizer/cda:component[1]/cda:substanceAdministration[1]/cda:code[1]/@codeSystem-->
                <xsl:when test="
                        $nodes/substanceAdministration[1]/code[1]/@codeSystem = '2.16.840.1.113883.6.96' and
                        $nodes/substanceAdministration/code/@code = '16076005'">
                    <xsl:value-of select="$BT_MA"/>
                </xsl:when>
                <xsl:when test="
                        $nodes/substanceAdministration[1]/code[1]/@codeSystem = '2.16.840.1.113883.6.96' and
                        $nodes/substanceAdministration/code/@code = '422037009'">
                    <xsl:value-of select="$BT_TA"/>
                </xsl:when>
                <!-- fout codesysteem, dat nu nog in een paar voorbeeldberichten voorkwam - - >      
  <xsl:when test="$nodes/substanceAdministration[1]/code[1]/@codeSystem = '2.16.840.1.113883.2.4.3.11.60.20.77.5.3' and   
    $nodes/substanceAdministration/code/@code = '4'">
    <xsl:value-of select="'ta'"/>
  </xsl:when>
        -->
                <xsl:when test="
                        $nodes/substanceAdministration[1]/code[1]/@codeSystem = '2.16.840.1.113883.2.4.3.11.60.20.77.5.3' and
                        $nodes/substanceAdministration/code/@code = '6'">
                    <xsl:value-of select="$BT_GB"/>
                </xsl:when>
                <xsl:when test="$nodes/supply">
                    <xsl:value-of select="$BT_SUPPLY"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$blockType"/>
    </xsl:function>
    <xd:doc>
        <xd:desc/>
        <xd:param name="blockType"/>
    </xd:doc>
    <xsl:template name="getBlockTypeIcon">
        <xsl:param name="blockType" as="xs:decimal"/>
        <!-- 
Relatieve paden om icons te laden: Alexander schrijft:
"Het verschil is of de server resolving doet of de client. Als de client aan de server vraagt 
“mag ik http://decor.test-nictiz.nl/art-decor/btM.gif van je?” Dan weet de server niet waar die vandaan moet komen.
Als je echter vraagt: “mag ik https://decor.test-nictiz.nl/xis/hl7/CDAr2/xsl/documentation/img/btM.gif” 
dan staat er een controller op de server die weet waar hij moet zijn.
Voor relatieve paden: vraag current path op met:         <xsl:value-of select="system-property('user.dir')"/>
      -->
        <xsl:choose>
            <xsl:when test="$blockType eq $BT_MA">
                <img src="{$ImagedataIconZorgverlener}"/>
            </xsl:when>
            <xsl:when test="$blockType eq $BT_TA">
                <img src="{$ImagedataIconApotheker}"/>
            </xsl:when>
            <xsl:when test="$blockType eq $BT_GB">
                <img src="{$ImagedataIconPatient}"/>
            </xsl:when>
            <xsl:when test="$blockType eq $BT_SUPPLY">SPLY</xsl:when>
            <xsl:when test="$blockType eq $BT_UNKNOWN">??</xsl:when>
        </xsl:choose>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationName">
        <!-- Since either the G-standard code, or the name (for composite) is filled, 
         just display both and the relevant one will appear. -->
        <xsl:value-of select="*/consumable[1]/manufacturedProduct[1]/manufacturedMaterial[1]/code[1]/@displayName"/>
        <xsl:value-of select="*/consumable[1]/manufacturedProduct[1]/manufacturedMaterial[1]/name[1]"/>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationStartDate">
        <!-- TODO: this might not be the right start date
     ++  currently we first check if effectiveTime has a value attribute,
     ++  if not it might be a TS_IVL with a low value. 
     ++  If neither we fall back to the date the author registered this. 
    -->
        <xsl:choose>
            <xsl:when test="*/effectiveTime/@value">
                <xsl:value-of select="nf:printHl7DateTime(*/effectiveTime/@value)"/>
            </xsl:when>
            <xsl:when test="*/effectiveTime/low">
                <xsl:value-of select="nf:printHl7DateTime(*/effectiveTime/low/@value)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationEndDateOrDuration">
        <xsl:choose>
            <xsl:when test="*/effectiveTime/high">
                <xsl:value-of select="nf:printHl7DateTime(*/effectiveTime/high/@value)"/>
            </xsl:when>
            <xsl:when test="*/effectiveTime/width">
                <xsl:value-of select="concat(*/effectiveTime/width/@value, ' ', */effectiveTime/width/@unit)"/>
            </xsl:when>
            <!-- otherwise: just leave empty -->
        </xsl:choose>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationDosage">
        <xsl:value-of select="*/hl7:text"/>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationRoute">
        <xsl:value-of select="*/routeCode[1]/@displayName"/>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationReason">
        <!-- 'text' instead of 'text[1]': show all reasons, if more than one happens to be present -->
        <xsl:value-of select="*/entryRelationship[1]/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9068']/text"/>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationRemark">
        <!-- 'value' instead of 'value[1]': show all remarks, if more than one happens to be present -->
        <xsl:value-of select="*/entryRelationship[1]/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9068']/value/@displayName"/>
    </xsl:template>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template name="getMedicationAuthor">
        <!-- Since the elements under 'name' are required to be in a right order, 
         just displaying 'name' will result in all available elements in the right order. -->
        <xsl:value-of select="//author[name(..) = 'organizer' or name(..) = 'ClinicalDocument']/assignedAuthor[1]/assignedPerson[1]/name"/>
        <!-- TODO: find out why the cda.xsl functions show-name etc. do not display anything -->
        <!--
    <xsl:if test="//author[name(..)='organizer' or name(..)='ClinicalDocument']/assignedAuthor/assignedPerson">
      <xsl:call-template name="show-name-set">
        <xsl:with-param name="in" select="//author[name(..)='organizer' or name(..)='ClinicalDocument']/assignedAuthor/name"/>
      </xsl:call-template>-->
        <!-- <xsl:call-template name="show-name">
        <xsl:with-param name="in" select="//author[name(..)='organizer' or name(..)='ClinicalDocument']/assignedAuthor/name[1]"/>
      </xsl:call-template>
    </xsl:if>
    -->
        <!-- Add the caregiver role -->
        <xsl:value-of select="
                if (//author[name(..) = 'organizer' or name(..) = 'ClinicalDocument']/assignedAuthor[1]/code) then
                    concat(' (', //author[name(..) = 'organizer' or name(..) = 'ClinicalDocument']/assignedAuthor[1]/code[1]/@displayName, ')')
                else
                    ''"/>
    </xsl:template>
</xsl:stylesheet>
