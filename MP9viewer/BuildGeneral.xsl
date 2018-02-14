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
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:nf="http://www.nictiz.nl/functions"
    xmlns="http://www.w3.org/1999/xhtml" 
    exclude-result-prefixes="xd hl7 xsi xhtml"
    xpath-default-namespace="urn:hl7-org:v3" 
    version="2.0">
    
  
    <xd:doc scope="stylesheet">
        <xd:desc>This NICTIZ stylesheet is part of MedViewer9, 
            and takes care of generating the general section of the viewer, containing information
            specific to a medication overview.
            All templates expect as current node: [hl7:ClinicalDocument | hl7:organizer]
        </xd:desc>
    </xd:doc>
    
    <!-- nictizFunctions is already included in the main source file so including it here again generates a warning. -->
    <!-- You can ignore squiggly lines in oXygen that it cannot find the nf: functions. -->
    <!--<xsl:include href="nictizFunctions.xsl"/>-->
    
    <xd:doc>
        <xd:desc>
            Creates a HTML table with patient and overview information from the XML source.
            Expected current node: [hl7:ClinicalDocument | hl7:organizer]
        </xd:desc>
    </xd:doc>
    <xsl:template name="buildGeneral">
        <h3 class="general">
            <xsl:value-of select="nf:getLocalizedString('general')"/>
        </h3>
        <table>
            <tr>
                <td class="labelLeft">
                    <xsl:value-of select="nf:getLocalizedString('date')"/> <xsl:text> </xsl:text>
                    <xsl:value-of select="nf:getLocalizedString('medicationOverview')"/>
                </td>
                <td class="contentLeft">
                    <xsl:call-template name="getDocumentDate"/>
                </td>
                <td class="labelRight">
                    <xsl:value-of select="nf:getLocalizedString('checkedByCaregiver')"/>
                </td>
                <td class="contentRight">
                    <xsl:call-template name="getCheckCareProviderDate"/>
                </td>
            </tr>
            <tr>
                <td class="labelLeft">
                    <xsl:value-of select="nf:getLocalizedString('length')"/> <xsl:text>, </xsl:text>
                    <xsl:value-of select="nf:getLocalizedString('weight')"/>
                </td>
                <td class="contentLeft">
                    <xsl:call-template name="getPatientHeightWeight"/> 
                </td>
                <td class="labelRight">
                    <xsl:value-of select="nf:getLocalizedString('verifiedWithPatient')"/>
                </td>
                <td class="contentRight">
                    <xsl:call-template name="getVerifyPatientDate"/>
                </td>
            </tr>
        </table>
    </xsl:template>


    <xd:doc>
        <xd:desc>
            Returns a string with the creation date of the medication overview.
        </xd:desc>
    </xd:doc>
    <xsl:template name="getDocumentDate">
        <xsl:value-of select="nf:printHl7DateTime(effectiveTime/@value, true())"/>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            Returns a string with the date a care provider validated the medication.
        </xd:desc>
    </xd:doc>
    <xsl:template name="getCheckCareProviderDate">
        <xsl:variable name="checkedDateTime" select="participant[templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9174' or templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9180']/time/@value"/>
        <xsl:choose>
            <xsl:when test="$checkedDateTime">
                <xsl:value-of select="nf:printHl7DateTime($checkedDateTime, true())"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="nf:getLocalizedString('answerNo')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            Returns a string with the date the medication was verified with the patient.
        </xd:desc>
    </xd:doc>
    <xsl:template name="getVerifyPatientDate">
        <xsl:variable name="checkedDateTime" select="participant[templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9173' or templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9179']/time/@value"/>
        <xsl:choose>
            <xsl:when test="$checkedDateTime">
                <xsl:value-of select="nf:printHl7DateTime($checkedDateTime, true())"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="nf:getLocalizedString('answerNo')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            Returns the most recently measured height and weight of the patient and their registration dates, as one string.
            Since height and weight are registered inside MA components, we collect all registrations within the 
            current ClinicalDocument/organizer and select the most recent of both height and weight. (could be from different MA's)
            (Since this template is only used for 'MedicatieOverzicht', we don't have to worry about merging data from different
            ClinicalDocuments/organizers; each MedicatieOverzicht gets it's own header.)
        </xd:desc>
    </xd:doc>
    <xsl:template name="getPatientHeightWeight">

        <!-- Find the most recent height recording within the current  and display it -->
        <xsl:for-each select=".//entryRelationship/observation[code/@code='8302-2']" >
            <xsl:sort select="./effectiveTime/@value" order="descending"/>
            <xsl:if test="position()=1">
                <xsl:value-of select="./value/@value"/>
                <xsl:value-of select="./value/@unit"/>
                <xsl:choose>
                    <xsl:when test="./effectiveTime/@value">
                        (
                        <xsl:value-of select="nf:printHl7DateTime(./effectiveTime/@value, true())"/>
                        )
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="./value">
                            (
                            <xsl:value-of select="nf:getLocalizedString('dateUnknown')"/>
                            )
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>     
        
        <!-- Add a separator only if either height and weight are present.
             (If only one is present, the user can see from the location of the comma whether it is height or weight.)
        -->
        <xsl:if test=".//entryRelationship/observation[code/@code='8302-2'] and 
                      .//entryRelationship/observation[code/@code='3142-7']">
            <xsl:text>, </xsl:text>
        </xsl:if>
        
        <!-- Find the most recent weight recording and display it -->
        <xsl:for-each select=".//entryRelationship/observation[code/@code='3142-7']" >
            <xsl:sort select="./effectiveTime/@value" order="descending"/>
            <xsl:if test="position()=1">
                <xsl:value-of select="./value/@value"/>
                <xsl:value-of select="./value/@unit"/>
                <xsl:choose>
                    <xsl:when test="./effectiveTime/@value">
                        (
                        <xsl:value-of select="nf:printHl7DateTime(./effectiveTime/@value, true())"/>
                        )
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="./value">
                            (
                            <xsl:value-of select="nf:getLocalizedString('dateUnknown')"/>
                            )
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>        
   
    </xsl:template>
        
</xsl:stylesheet>