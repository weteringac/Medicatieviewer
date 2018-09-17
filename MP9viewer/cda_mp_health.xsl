<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:hl7="urn:hl7-org:v3" xmlns:hl7nl="urn:hl7-nl:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nf="http://www.nictiz.nl/functions" xmlns:pharm="urn:ihe:pharm:medication" xmlns:util="urn:hl7:utilities" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xd hl7 xsi xhtml" xpath-default-namespace="urn:hl7-org:v3" version="2.0">

	<xsl:import href="BuildHeader.xsl"/>
	<xsl:import href="BuildGeneral.xsl"/>

	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p>This stylesheet transforms a Medication Process 9 XML file with therapeutic building
      blocks to a HTML presentation that displays the most important data of each block as a line in
      a table. The blocks are grouped by active status (current, future or recent past), by
      treatment group ('medicamenteuze behandeling' = MBH) and by type ('medicatieafspraak',
      'toedieningsafspraak', 'gebruik').</xd:p>
			<xd:p>The input XML is based on the AORTA 9.0.6 specification.</xd:p>
			<xd:p>Note that this transformation uses XSLT (and XPATH) 2.0, which not all XML tools and browsers support.</xd:p>
		</xd:desc>
	</xd:doc>

	<xd:doc>
		<xd:desc>
			<xd:p>Use XHTML 1.0 Strict with UTF-8 encoding. (HTML 5 was not chosen because of compliancy
        with other Art-Decor transformations.)</xd:p>
		</xd:desc>
	</xd:doc>
	<xsl:output indent="yes" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>


	<!-- For XSD schema validation in XSL Saxon-EE is required. That version is not available in Art-Decor,
    but it is in oXygen, so the line below can be uncommented during development, but must be commented 
    before distribution. -->
	<!--<xsl:import-schema namespace="urn:hl7-org:v3"
    schema-location="../SVN/Onderhoud_Mp_v90/XML/schemas_codegen/CDANL_extended.xsd"/>-->

	<xsl:include href="nictizFunctions.xsl"/>

	<!-- variables for template ids -->
	<!-- Note that there is also a MA template 9185, but that is only used for proposal messages, which this viewer doesn't support -->
	<xsl:variable name="ma_templateId" as="xs:string*" select="'2.16.840.1.113883.2.4.3.11.60.20.77.10.9148', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9202', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9216'"/>
	<xsl:variable name="ta_templateId" as="xs:string*" select="'2.16.840.1.113883.2.4.3.11.60.20.77.10.9152', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9205', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9223'"/>
	<xsl:variable name="gb_templateId" as="xs:string*" select="'2.16.840.1.113883.2.4.3.11.60.20.77.10.9154', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9190', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9209', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9224'"/>
	<xsl:variable name="mbh_templateId" as="xs:string*" select="'2.16.840.1.113883.2.4.3.11.60.20.77.10.9084'"/>
	
	
	<!-- Document Types enumeration  ('Constants' for the different types)
       for this viewer only a few types are supported:
        MO = medication overview - srtuctured collection of components from a single source
        MEDDATA = 'medicatie gegevens' - loose collection of components, likely from different sources 
    -->
	<xsl:variable name="DOCTYPE_OTHER" select="0" as="xs:decimal"/>
	<xsl:variable name="DOCTYPE_MO" select="1" as="xs:decimal"/>
	<xsl:variable name="DOCTYPE_MEDDATA" select="2" as="xs:decimal"/>
	<xsl:variable name="DOCTYPE_GEBRUIK" select="3" as="xs:decimal"/>

	<!-- Component Types ('bouwsteen types') enumeration ('Constants' for the different types):
       MA = 'medicatie afspraak'       
       TA = 'toedienings afspraak'       
       GB = 'medicatiegebruik'
       (currently the viewer doesn't support the 'toediening' component type) 
       supply = contains logistics information, that is not the focus of this viewer        
  -->
	<xsl:variable name="CT_UNKNOWN" select="0" as="xs:decimal"/>
	<xsl:variable name="CT_MA" select="1" as="xs:decimal"/>
	<xsl:variable name="CT_TA" select="2" as="xs:decimal"/>
	<xsl:variable name="CT_GB" select="3" as="xs:decimal"/>
	<xsl:variable name="CT_SUPPLY" select="10" as="xs:decimal"/>

	<!-- Table type enumeration, signifying whether the 'MBH' 
       has recently stopped being active, is currently active, or will become active in the near future.
       MBH's that are too far in the past or in the future are not displayed and get table NONE.
  -->
	<xsl:variable name="TABLE_NONE" select="0" as="xs:decimal"/>
	<xsl:variable name="TABLE_PAST" select="1" as="xs:decimal"/>
	<xsl:variable name="TABLE_CURRENT" select="2" as="xs:decimal"/>
	<xsl:variable name="TABLE_FUTURE" select="3" as="xs:decimal"/>

	<!-- StopType enumeration: the possible values that can occur in the XML:
       Temp[orary] - 'tijdelijk onderbreken'
       Abort - '(permanent) staken'
    -->
	<xsl:variable name="STOPTYPE_NONE" select="0" as="xs:decimal"/>
	<xsl:variable name="STOPTYPE_TEMP" select="1" as="xs:decimal"/>
	<xsl:variable name="STOPTYPE_ABORT" select="2" as="xs:decimal"/>

	<!-- Binary data of the 3 icons for the block types. In Art-Decor it won't work to just load icons from the current folder, and the method that works for Art-Decor doesn't automatically work when the transformation is done locally in oXygen. 
    Including the icon data makes the resulting html somewhat larger, but at least works in both cases.
  -->
	<xsl:variable name="ImagedataIconCareProvider"
		select="'data:image/gif;base64,R0lGODlhDQATAPcAAN81N/Gdn+dpa/fPz+uDg+FRU/O5u+l3eedDQ/3x8e2TlfGvr98/QedxceuJifnd3fOnp+l9f+85O+uHh+lfX/fHyf35+euFh+dXWel1dffV1eFLTfGhoedtbeuFhfXBwel7e/nl5fGpq+mBgfs7Pf/9/d87Pe+fn/nT1eFHSfOXl/O1tf89P+lzdfGpqetbW+k3OfvR0euDheVTVfW9ve15ef339/Wxs+FBQ+1zc+uNj/vh4fenqfnNzf/7++91d+dvcemBg/07P++foedrbffP0edRU/O7u+93ee1FR/3z8+2VlfOvr+s9P+lxc/vf3/Gnqel/gfM5O+2Hh+VlZ/fJy//5+e+Fh+lXWel1d/nX1+NNT+ttb+2FhfXDw/F7ffvn5/07Pf///+dHSe+Zme9bW+s3O+2Dhe2Nj+uBg/GfoQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAANABMABwi8AMUIfFDEh0CBJQQmOFEDQ4MZBKIAOQDBhhglUH4YIQLDxJYNAFhQsXCwxw0tKHaISZCGRJWDByMKHCJkwMEQPFzIiEKGAokGCcXQaEIiw4Q0HcqcsCLQAoMXT8S0mABToBUTRBL4MPAhKMwVEjqmYIDjjEWYKJZciBAkiwQFVQ96WCBGR4G4Dz50mABlDFyYBpIEcVJDAIe4KSBIpRtXTBoMAXQEqGAw7o0rF9IgodFY4AEvYio3HgCmakAAOw=='"/>
	<xsl:variable name="ImagedataIconPharmacist"
		select="'data:image/gif;base64,R0lGODlhEwATAPcAACkpKZeXl1tbW8/Pz0NDQ+np6XV1dTc3N2lpaU9PT/X19bOzs93d3WNjY4ODgzExMUlJSe/v7z09PVVVVfv7+729vaWlpW9vb+Pj419fX9nZ2Xt7e7m5uS0tLUdHR+3t7Ts7O1NTU/n5+WdnZ4uLizU1NU1NTfPz80FBQVlZWf///62trXNzc+fn539/f5ubm11dXdPT00VFRevr6zk5OW1tbVFRUff397e3t+Hh4WVlZYWFhTMzM0tLS/Hx8T8/P1dXV/39/cPDw6mpqXFxceXl5WFhYdvb2319fbu7uy8vLwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAATABMABwjyAFUIHEiwoIggBRMWHCCgxgyFClckkMFjCESCPkgQMCGhQYuLAjVcSJCARoaHAxEWxAHDRoIDMD6AVBAggQ0IHTKIKFgAxwIOFXC48ABBggQlFyz4IJjkgIcLDoh4KKEEwAEUNA4wICjEgw0YOoxAAPGgw4MSNAjkIBgjRQojCIwkIACiBFoaCSIQjMBCQIa4CTz8AEGDMIKEL4AIgCHAhAyjIH4osZCwyAUgKSb08ECAAFYYJxQeYZECAgEZKH7Q6IHhogMgNWDIAFHXyEUFMHps0AFCiRIeEopAPIEEBpIGNIAnICLzoggfH1oUiEBBYUAAOw=='"/>
	<xsl:variable name="ImagedataIconPatient"
		select="'data:image/gif;base64,R0lGODlhEwATAPcAADGJx53F42ep20eZ1dnn8z2RzTOR1e/1+bfV6T+V1TGNz1Wd0a/P5/f7/TGNzePv9zGJy0mXzcff8TWV2Ye74UOTzZvJ6fP5+73Z7WOl0zmX2S+JyTmZ3zmT0TWT2evz+aHH49vr9TuT1bXV7U+d17PT6f///5vD4Z3H5XWv2TWT1fH3+7fV6/v9/efx9zGLyzmV2Y293/f5/TeX2zOJyT2b3z2T0d/t9zOJx5nF5U2d1T+Rze/1+z2X1zGP01mf0bHR6ePv+cnh8TeV2Ym74UWTzaXL5/f5+8Pb7Vmj2TGJyTmZ4TuT0e3z+VWf1a/T632z2TOT17nV6/39/TGLzTmX2+Ht9wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAATABMABwjPAE0IHEiwoMGDCBPKkDBCyJGEBIHo8ECRhBSIJhjUoKIEAAAINRAkPLADAg4ANAAogVBkBUIEEzymRAnAAwaEATzg6JgSBw4PRhAy0KDy5M6aIg8+YAIBwNGPBT4kPLFkg8ePHEBgzJFghocZTAJAvHDDxAcgFoDwMBFkykECSRIQsSJwSggKCQS4KGhlgAIlBphEWBChgwHAJFwOzGCgqBIqkDt6nABlIBKiTj2evOpRSYcQAlMY2MxZ81UPMUy0KEKFBg4asGPPdK3gh4mAADs='"/>

	<xsl:variable name="ImagedataIconMedication"
		select="'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAABR1BMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwILCwsDAwIDAwNEREAAAAAAAABEREBEREBEREAAAAAAAAAAAAAHBwZEREBEREBEREAAAAAAAABEREAAAAABAQEAAAAAAABEREABAQEQEA8AAAAAAAALCwoDAwMAAAAEBAMDAwMFBQUCAgEAAAACAgIAAAAAAAAAAAAAAAA/PzwODg0ICAgCAgIAAAAAAAACAgIiIiAFBQUAAAAAAAAAAAABAQESEhEFBQUAAAAAAAAJCQgGBgUAAAAAAAAAAAAAAAAEBAQyMi8AAAAAAAAAAAAAAAAAAAAAAAAAAAAICAcAAAAAAAABAQELCwoAAAAAAAADAwMcHBoAAAAAAAADAwMKCgkAAAACAgIDAwMYGBcAAAAAAAADAwISEhACAgIAAAAAAAABAQEAAAAEBAMAAABabf4lAAAAZnRSTlMAR5GLOIhsDxqGbgE2egEJCpsUmhINDwJWSgQWlWs3BXw6pwEErXNV/bdIEb/acSeVDklrPSr+MhrEvAyUxjm8/upjmiWP8PnqFfjGWhBnxbuKseeDGyvr0RUh4uEieJhqDHCVcRQlhauTAAAAyElEQVQYGQXBMUvDQACA0e+73CWpLXWSgFJx0E0cRBd/tLu7buKgdGxBBCWIVLEFteHO9wRAdQAAAZKqbgAiMFEtwQ0wjkCjlqDAdBLgYKQl9ClBZ4qQ/CuhJ0mX3QaO06aEnsO46LLlq2Iv7IyrFXE3ZMuwltMrvVPf9tV7vLwwAw/q+eCjoakyQLOs67mcGdIAUJLpJy6WpFgDlOemNCcv+jqNI6DE0W1omfGuoV4Rykf727ff0LVtNf+cbXO6XvN01Oacbv4BnUM+zPdO/VAAAAAASUVORK5CYII='"/>
	<xsl:variable name="ImagedataIconPrescribe" select="'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAB7QAAAe0BDNry2gAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAE0SURBVDiNldExa5RBEIfx38QzCEaQYECw8UsErbRRCESJlW0KP4OQXpton94uTapIjAQSLAInCkIglbEStLAQxM7ib+FefHPcvejTDDu7++zMTiUxoqqu4Bjf/WUeq0lemUDhGp5gBnOYS7LUka7hHk5a6kWSg9H+AIstbuAq1tulEbexjx3cxArOCOBLkmF78RwudQSbOExyUlWXcb3bwsAYSbbO9Fi1hMOqWp30BzOTkmN8xOcW/1+Q5BNutDiqaqGqHlfVhUEneR/Pp4mqahPDtnyIZzg+FSTZxnZfNe0/4HyLs/9cgT/TGI4nu1N4ib0ewS/c7RMs42mPYAvv+gS7eN8j+IFbfYI7WBs/0GEHR1MFSXZbFVPpTOENfuLtAN/wqKoe9F1uXMRGkg9V9TrJ199+nllgrC+dAQAAAABJRU5ErkJggg=='"/>
	<xsl:variable name="ImagedataIconStop"
		select="'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyZJREFUeNpUU8tvE2cQ/+3Du3YWmyUmgVBIRCG4blVcpJQTRebQgyl1EWoqQDyaXqq2UntrqFpxQBwoEn8CEikSAjV9UFQc0UN9oBLQRGYbqvKKUGJiBfLw2l5vvM+P2SUUmE8jfTPzzes383GnEIcHwCeuv74pwwFFBqg+GBhd2JKNhQc6vc323q5p7ookziaqEB3w4YNqekOGY6y4p39ATXW+CmOiDGuuCs+2wcsS5I4k7uhT6i9/XSreSsWz18x5rUUhuRPowEx6bZg5v2OPGq26uDeuQWkYkJtNMM9HXRIxExWwrqsbXFzCyNSoThVm66an8Q9feyXjUub3tn+gypM1SD1J9F8dgrlGwYI+jflGBeZ6FZ/dvASlbwOMBxXsSKZVh3ykGJ/hPk1lqvt2H1Rjdxcg9a7CW99/iYAsvY7fcwcIHx/5wjnIaiLUX/z8WzweuYFY92pcrJR0DKTeZI+OnWPDve+zVrXGXiSLZGtJ59ke8z2fmVWdfZPYxIqb97P8xjTjbYK68d8E5OoCruQG4FDmZyRR1oDdhg3f8mDV6ziz8yOsNVvQy5MIfMMArcojyI0a5NESruc+fimINbcIz3ThuYsYzu2D8vc/SLoOFg0dFDYI4MM2DDiuRQov5Bed7ccmhGWRUHZpbBbZLbq1vNZSBaT0gioEetS3BdsKZxFZKpsMiPUkwIs8pOVx7C2ch/12BvMiB5rc8xZ4pQ3NaAzvFn4Ie/YdWi2OAye7dG+Bk3iQhKi6HJ9cHsYk7YTPCwiqD1rQrzuzUMQYxgZPhqVyAgefer6SO4RC7jDsWoOUT9v67chRKA6HfxVQu0wX1qxoHykZM3s7+GiUXRsndMvo2r4VvxJg9ugYFivTKP15FekPd+GnrwYxPnQBc6KIP5LQaZGzXH/vG7jvtjKEQzFfb1O7mw4aoouYVYcYAgvUyGE2+A8Ow1xEQHGlpJM62yNKWjiF0+3vaA7t9o9xQ7+nRJAw6ee5ApqIwIAQwI/Opo/ZSOR/5+/KghbgJz6bwvFKTPu6y8z+HDeK9MNVIIqn/BKFzl9Mm5rLloVTeCLAAAugtkxNJDycAAAAAElFTkSuQmCC'"/>
	<xsl:variable name="ImagedataIconTempStop" select="'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAABnRSTlMA/wD/AP83WBt9AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAmElEQVQokZVSSQ7DMAhkUL+Tqmp+0f/LUe79x+RAY+ExUVRONjAL2CBp/8RD7gAkI4xedpPsfULhZbfQZ8ygkMuC71cv6cVG1hwUJGTcYPG5rIsGDOipWuGHASx5C6/FliK+2x5QC/B5QJ5yMBP4yZ5nD/MzZ0tWDq2YrEDa1cMB+LzWUgflbwVA0maHN2sl38uzJ7fWjDwAfMNcZzXriEUAAAAASUVORK5CYII='"/>

	<xsl:variable name="ImagedataIconRefCareProvider"
		select="'data:image/gif;base64,R0lGODlhDwAOAPcAAAEBAeuBgcHBwd1DReVlZ/Gho+dzdfnh4e2Pj+VVV/Oxsel7e/3x8emLi+l/gd0NE+mFheNNT/35+espLelvb/O5ud85O/fT0+1/f/lFR/GvsemHif09P+tra/Glpf3t7eVfY/N7e/v39+uHh98/QeuDheFJS+1lZ/vl5fO3t/F/ge+Fhf/9/fW/wfvb2/XBw++jo+d3ee1XWfOzs+19f+2Njel/g+dRU+lxc/e7u//39+k9P+dJS/vn5+uBg+lnZ++bm+dXWel7ff3z8+uLi+t/geuFh/FLS//5+e0vM+dxcfO5u+k3N/fX1+9/f/1HSfGlqe9hYe99f/339/GDhe9naf3l5+2Fh/////nd3ffHx++jpe13d/Wzs+0/Q+dJTQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAFgALAAAAAAPAA4ABwirALEIZKAAQ4cbCTAYMUAjhw6BWIYsUXGCBxMLEQYkyUAAIkQWWHQgANFEBBUOHkFKuOChhA0DRzIogSiAxQEhOxaMIPIjSgokEAEIMPKggIQXCnp4FAhAaIgJJEyQSKCAadOrAloEWNBAhhcNWK6KFVCBAgQCPMCKbSrAgwMcXEpoWcp2iwEsNoigwAIyqAAJWFBIKeEAiIu+AgUIBKnDAYwPSyOzuJAFqMCAADs='"/>
	<xsl:variable name="ImagedataIconRefPharmacist"
		select="'data:image/gif;base64,R0lGODlhEwANAPcAAAEBAYODg0FBQc/Pz2FhYSkpKTU1Nevr61FRUaWlpXFxcTs7O/n5+UtLSy8vL7e3t+Pj421tbUVFRTk5OfPz811dXa2trXt7ez8/P/39/TMzM5eXl0NDQ9nZ2WVlZS0tLTc3N+3t7ampqT09PU9PTzExMcHBweXl5W9vb19fX319ff///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAACsALAAAAAATAA0ABwiEAFcIHEiw4IAIBwoqJGiBhAYRCxV2IEFiQsKFGQg+qEACRIWIBTeQQPAhBQOQJlAEUGDAQQEBE0BEBLDCBAECC0p8MDCBw0yaNjks4DmBREEASJPWlDBiBAYHCY4mVWqCA4cJFShInbpUAIYGEEAirXlhgQMHI06IrVlBxQQNIxSEIBgQADs='"/>
	<xsl:variable name="ImagedataIconRefPatient"
		select="'data:image/gif;base64,R0lGODlhEgAOAPcAAAEBAYGBgZvD4TGJx2ep20mXzdvr9TmT0bfV6T2RzTWV2fH3+zGLzevz+a/P5zGJy8ff8TmZ3zGJyVWd0ePv9zWT2aHH44e74TOR1b3Z7UWTzf39/T2b3zOJxz+V1d/t9zuT0bXV7T+RzTmX2TGNz+/1+bHR6cnh8TmZ4TOJyVmf0ePv+ZvJ6Y293////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAC4ALAAAAAASAA4ABwiUAF0IHEiwoMGDEEKcOGjQAQcJAwZwQMBQYAkRDwakGPBAw4KKCBRojDigQgaDATa4cDBiQAeXJSkWBBDABQUQDzpAfJCggUEANDcIQEEyggWCQJPS/ODCBAsTLlaoFKg0aU2BGy54IDCwKk0XGApMKIBBAoaPSL++fElywAEDSGu2jci2QguCNRl0SMGXb8QUJFQEBAA7'"/>

	<xd:doc>
		<xd:desc>First entry template: start at the root of the document, add the HTML header and
      footer, call the external processing for the header and generic sections,  group all
      components ('bouwstenen') by MBH, and display the groups in separate tables depending on
      whether they are, will become, or were active.</xd:desc>
	</xd:doc>
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="hl7:MCCI_IN200101">
				<xsl:apply-templates select="hl7:MCCI_IN200101"/>
			</xsl:when>
			<xsl:when test="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:ClinicalDocument">
				<xsl:for-each select="hl7:QUMA_IN991203NL01/hl7:ControlActProcess/hl7:subject[hl7:ClinicalDocument]">
					<!-- Show the most recent MO first (in case these are MO's - otherwise the sorting has no effect) -->
					<xsl:sort select="*/effectiveTime/@value" order="descending"/>
					<xsl:call-template name="processDocumentOrOrganizer">
						<xsl:with-param name="doHeader" select="true()"/>
					</xsl:call-template>
				</xsl:for-each>
				<!--<xsl:apply-templates select="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:ClinicalDocument">
          <xsl:with-param name="doHeader" select="true()"/>
        </xsl:apply-templates>-->
			</xsl:when>
			<xsl:when test="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:organizer">
				<xsl:for-each select="hl7:QUMA_IN991203NL01/hl7:ControlActProcess/hl7:subject[organizer]">
					<!-- Show the most recent MO first (in case these are MO's - otherwise the sorting has no effect) -->
					<xsl:sort select="*/effectiveTime/@value" order="descending"/>
					<xsl:call-template name="processDocumentOrOrganizer">
						<xsl:with-param name="doHeader" select="true()"/>
					</xsl:call-template>
				</xsl:for-each>
				<!--<xsl:apply-templates select="hl7:*[hl7:interactionId]/hl7:ControlActProcess/hl7:organizer">
          <xsl:with-param name="doHeader" select="true()"/>
        </xsl:apply-templates>-->
			</xsl:when>
			<xsl:when test="hl7:ClinicalDocument | hl7:organizer">
				<xsl:call-template name="processDocumentOrOrganizer">
					<xsl:with-param name="doHeader" select="true()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Element not supported <xsl:value-of select="name()"/></xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xd:doc>
		<xd:desc>Processes a full message, complete with wrappers</xd:desc>
	</xd:doc>
	<xsl:template match="hl7:MCCI_IN200101">
		<html>
			<xsl:call-template name="addHtmlHead"/>
			<body>
				<xsl:for-each select="hl7:QUMA_IN991203NL01/hl7:ControlActProcess/hl7:subject[hl7:ClinicalDocument or hl7:organizer]">
					<!-- Show the most recent MO first (in case these are MO's - otherwise the sorting has no effect) -->
					<xsl:sort select="*/effectiveTime/@value" order="descending"/>

					<xsl:call-template name="processDocumentOrOrganizer">
						<xsl:with-param name="doHeader" select="false()"/>
					</xsl:call-template>
				</xsl:for-each>

				<!-- Comment the next line for a 'clean' version. The toggle allows adding extra and debug information to the grid. -->
				<br/>
				<input type="checkbox" id="toggleDebugVisible" onclick="toggleDebug()">Toon additionele informatie</input>
			</body>
		</html>
	</xsl:template>

	<xd:doc>
		<xd:desc>Processes a single document, whether it is a complete ClinicalDocument or only an organizer.</xd:desc>
		<xd:param name="doHeader">Whether a head-section should be added to the html: that should only be done once.</xd:param>
	</xd:doc>
	<!--<xsl:template match="hl7:ClinicalDocument | hl7:organizer">-->
	<xsl:template name="processDocumentOrOrganizer">
		<xsl:param name="doHeader" as="xs:boolean" required="yes"/>

		<xsl:choose>
			<xsl:when test="$doHeader">
				<html>
					<xsl:call-template name="addHtmlHead"/>
					<body>
						<xsl:apply-templates select="." mode="doContent"/>

						<!-- Comment the next line for a 'clean' version. The toggle allows adding extra and debug information to the grid. -->
						<br/>
						<input type="checkbox" id="toggleDebugVisible" onclick="toggleDebug()">Toon additionele informatie</input>
					</body>
				</html>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="doContent"/>
				<br/>
				<br/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xd:doc>
		<xd:desc>Processes the contents of a single document, whether it is a complete ClinicalDocument or only an organizer.</xd:desc>
	</xd:doc>
	<xsl:template match="hl7:ClinicalDocument | hl7:organizer" mode="doContent">

		<!-- Display in the title if it is an overview or a collection of components.  -->
		<xsl:variable name="docType" select="nf:determineDocumentType(..)"/>
		<div class="title">
			<xsl:choose>
				<xsl:when test="$docType = $DOCTYPE_MO">
					<xsl:value-of select="upper-case(nf:getLocalizedString('medicationOverview'))"/>
				</xsl:when>
				<xsl:when test="$docType = $DOCTYPE_MEDDATA">
					<xsl:value-of select="upper-case(nf:getLocalizedString('medicationData'))"/>
				</xsl:when>
				<xsl:when test="$docType = $DOCTYPE_GEBRUIK">
					<xsl:value-of select="upper-case(nf:getLocalizedString('medicationUsageData'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="upper-case(nf:getLocalizedString('unsupportedDocument'))"/>
				</xsl:otherwise>
			</xsl:choose>
		</div>

		<!-- header section -->
		<xsl:call-template name="buildHeader">
			<xsl:with-param name="isMO" select="$docType = $DOCTYPE_MO"/>
		</xsl:call-template>

		<!-- section 'algemeen' -->
		<xsl:if test="$docType = $DOCTYPE_MO">
			<xsl:call-template name="buildGeneral"/>
		</xsl:if>

		<xsl:variable name="curContext" select="."/>

		<!-- Create a group per MBH based on the MHB id, with parameters for startDate, stopDate and target table -->
		<xsl:variable name="mbhList" as="element()*">
			<xsl:for-each-group select="//*[hl7:templateId[@root = $mbh_templateId]]" group-by="hl7:id/concat(@root, '#', @extension)">
				<xsl:variable name="mbhStartDate" as="xs:dateTime" select="nf:determineMBHstartDateTime(current-group())"/>
				<xsl:variable name="mbhStopDate" as="xs:dateTime" select="nf:determineMBHstopDate(current-group())"/>
				<xsl:variable name="mbhTable" as="xs:decimal" select="nf:determineMBHtable($mbhStartDate, $mbhStopDate)"/>
				<mbh id="{current-grouping-key()}" startdatum="{$mbhStartDate}" stopdatum="{$mbhStopDate}" table="{$mbhTable}"/>
			</xsl:for-each-group>
		</xsl:variable>

		<!-- Loop over all MBS's, reverse sorted by start date and display each component -->

		<!-- First the MBH's that are currently active -->
		<h3 class="current">
			<xsl:value-of select="nf:getLocalizedString('currentMedication')"/>
		</h3>

		<table class="current" border="1">
			<xsl:call-template name="createTableHeader">
				<xsl:with-param name="tableType" select="$TABLE_CURRENT"/>
			</xsl:call-template>

			<xsl:for-each select="$mbhList">
				<xsl:sort select="@startdatum" order="descending"/>

				<xsl:if test="@table = $TABLE_CURRENT">
					<xsl:call-template name="DisplayMBH">
						<xsl:with-param name="curContext" select="$curContext"/>
						<xsl:with-param name="curMBH" select="@id"/>
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

			<xsl:for-each select="$mbhList">
				<xsl:sort select="@startdatum" order="descending"/>

				<xsl:if test="@table = $TABLE_FUTURE">
					<xsl:call-template name="DisplayMBH">
						<xsl:with-param name="curContext" select="$curContext"/>
						<xsl:with-param name="curMBH" select="@id"/>
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

			<xsl:for-each select="$mbhList">
				<xsl:sort select="@startdatum" order="descending"/>

				<xsl:if test="@table = $TABLE_PAST">
					<xsl:call-template name="DisplayMBH">
						<xsl:with-param name="curContext" select="$curContext"/>
						<xsl:with-param name="curMBH" select="@id"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
		</table>

	</xsl:template>


	<xd:doc>
		<xd:desc>Add the whole head section of the HTML, including css en javascript</xd:desc>
	</xd:doc>
	<xsl:template name="addHtmlHead">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
			<title>Viewer MP9 -
        <xsl:value-of select="(tokenize(document-uri(/), '/'))[last()]"/>
				<!-- Add the filename of the input file -->
			</title>
			<!-- In Art-Decor you can't just load remote resources, so for now just incorporate the styles -->
			<!--<link rel="stylesheet" href="medviewer9.css" type="text/css" media="screen" charset="utf-8"/>-->
			<style type="text/css">
				*
				{
					font-family: Verdana, Tahoma, sans-serif;
					font-size: 9pt;
				}
				body
				{
					padding: 2px;
				}
				.title
				{
					font-weight: bold;
					font-style: italic;
					font-size: 110%;
					text-align: center;
				}
				
				h3
				{
					margin-bottom: 0px;
					padding: 2px 4px;
					color: white;
					font-size: 120%;
					font-weight: bold;
				}
				h3.general
				{
					background-color: rgb(156, 194, 229);
				}
				h3.current
				{
					background-color: rgb(68, 114, 196);
				}
				h3.future
				{
					background-color: rgb(68, 84, 106);
				}
				h3.past
				{
					background-color: rgb(165, 165, 165);
				}
				
				table
				{
					width: 100%;
					border-spacing: 0px;
				}
				th
				{
					background-color: lightgray;
					text-align: left;
					padding: 2px 5px 2px 5px;
				}
				td
				{
					padding: 2px 5px 2px 5px;
				}
				td.labelLeft
				{
					width: 15%;
					font-style: italic;
				}
				td.contentLeft
				{
					width: 45%;
				}
				td.labelRight
				{
					width: 20%;
					font-style: italic;
				}
				td.contentRight
				{
				}
				td.current
				{
					border: 1px solid rgb(68, 114, 196);
				}
				table.current
				{
					border: 1px solid rgb(68, 114, 196);
				}
				.hideDebugInfo
				{
					display: none;
				}</style>

			<!-- In Art-Decor you can't just load remote resources, so for now just incorporate the JavaScript -->
			<!--<script src="medViewer9.js" />-->
			<script type="text/javascript">
        /* This function toggles the visibility of all table rows containing information of the same MBH,
        except for the topmost row of that MBH, which is always visible and from which the toggle is triggered. 
        It should be called from an element with an onclick method, like a button or hyperlink.              
        */
        function ToggleMBH(node)
        {
          var displayMode;
          if (node.innerText == "-")  // if MBH is to be collapsed
          {
            node.innerText = "+";
            displayMode = 'none';
            // Make a possible collapse button in the second row invisible
            if (node.parentNode.nextElementSibling.firstElementChild)
            {
              node.parentNode.nextElementSibling.firstElementChild.style.display = 'none';
              node.parentNode.nextElementSibling.firstElementChild.innerText = '+';
            }
          }
          else
          {
            node.innerText = "-";
            displayMode = '';
            // Make a possible collapse button in the second row visible
            if (node.parentNode.nextElementSibling.firstElementChild)
            {
              node.parentNode.nextElementSibling.firstElementChild.style.display = '';
            }
          }
          
          // Go through all rows and toggle its visibility if it is part of the same MBH 
          var sibling = node.parentNode.parentNode;  // Go to the TR node
          while (sibling = sibling.nextElementSibling)
          {
            if (sibling.className == node.parentNode.parentNode.className)
            if ((sibling.id != node.parentNode.parentNode.id) || (node.innerText == "+"))
            {
              // Set hide all rows when collapsing
              if ((displayMode != '') || (sibling.id != sibling.previousElementSibling.id))
              sibling.style.display = displayMode;
              if (displayMode == 'none')
              {
                // set all second column collapse button texts to '+'
                if (sibling.firstElementChild.nextElementSibling.firstElementChild)
                sibling.firstElementChild.nextElementSibling.firstElementChild.innerText = '+';             
              }
              else
              {
                if (sibling.firstElementChild.nextElementSibling.firstElementChild)
                sibling.firstElementChild.nextElementSibling.firstElementChild.style.display = '';             
              }
            }
          }
        }
        
        function ToggleID(node)
        {
          var displayMode;
          if (node.innerText == "-")  // if ID is to be collapsed
          {
            node.innerText = "+";
            displayMode = 'none';
          }
          else
          {
            node.innerText = "-";
            displayMode = '';
          }
          
          // Go through all rows and toggle its visibility if it is part of the same MBH 
          var sibling = node.parentNode.parentNode;  // Go to the TR node
          while (sibling = sibling.nextElementSibling)
          {
            if (sibling.id == node.parentNode.parentNode.id)
              if (sibling.className == node.parentNode.parentNode.className)
                sibling.style.display = displayMode;
          }
        }        	
        
        function toggleDebug()
        {
          var debugElements = document.querySelectorAll('[id^=debugInfo]');
          for(var i in debugElements)
          {
            debugElements[i].classList.toggle('hideDebugInfo');
          }
        }
      </script>
		</head>
	</xsl:template>

	<xd:doc>
		<xd:desc>
			<xd:p>Determine which kind of content the document contains: a medication overview
        ('Medicatieoverzicht' = MO), an unstructured collection of components ('Medicatiegegevens' =
        MEDDATA), or something else that is not recognized.</xd:p>
		</xd:desc>
		<xd:param name="topNode">the location within the document. This should be the top level
      of the entire document, which contains either one or more ClinicalDocument(s) or
      organizer(s).</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineDocumentType" as="xs:decimal">
		<xsl:param name="topNode" as="node()*"/>
		<xsl:choose>
			<xsl:when test="
					($topNode//organizer/templateId[@root = ('2.16.840.1.113883.2.4.3.11.60.20.77.10.9132', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9204')] or
					$topNode//ClinicalDocument/templateId[@root = ('2.16.840.1.113883.2.4.3.11.60.20.77.10.9146', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9207')])">
				<xsl:value-of select="$DOCTYPE_MO"/>
			</xsl:when>
			<xsl:when test="
					($topNode//organizer/templateId[@root = ('2.16.840.1.113883.2.4.3.11.60.20.77.10.9104', '2.16.840.1.113883.2.4.3.11.60.20.77.10.9221')] or
					$topNode//ClinicalDocument/templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9133'])">
				<xsl:value-of select="$DOCTYPE_MEDDATA"/>
			</xsl:when>
			<xsl:when test="
					($topNode//organizer/templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9125'] or
					$topNode//ClinicalDocument/templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9138'])">
				<xsl:value-of select="$DOCTYPE_GEBRUIK"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$DOCTYPE_OTHER"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>


	<xd:doc>
		<xd:desc>
			<xd:p>Returns the start date (and time) of a single component. This is either the start
        date, or if not specified, the registration date.</xd:p>
		</xd:desc>
		<xd:param name="componentNode">The root of the component ('substanceAdministration').</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineStartDateTime" as="xs:dateTime">
		<xsl:param name="componentNode" as="node()*"/>

		<xsl:variable name="startDate" select="$componentNode/effectiveTime/low/@value"/>
		<xsl:variable name="registerAuthorDate" select="$componentNode/author/time/@value"/>
		<!-- patient as author is also in author since 9.0.6, so variable below is only kept for backwards compatibility reasons -->
		<xsl:variable name="registerPatientDate" select="$componentNode/participant[@typeCode = 'AUT' and participantRole/@classCode = 'PAT']/time/@value"/>
		<xsl:variable name="isStop" as="xs:boolean" select="exists($componentNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067'])"/>

		<xsl:choose>
			<xsl:when test="$startDate and not($isStop)">
				<xsl:value-of select="nf:convertDateTime($startDate)"/>
			</xsl:when>
			<!-- The startDate of a stop is the same as the original component, 
           so in that case we add 1 minute to the start or registration date for sorting purposes. -->
			<xsl:when test="$isStop">
				<xsl:choose>
					<xsl:when test="$startDate">
						<xsl:value-of select="nf:convertDateTime($startDate) + xs:dayTimeDuration('PT1M')"/>
					</xsl:when>
					<xsl:when test="$registerAuthorDate">
						<xsl:value-of select="nf:convertDateTime($registerAuthorDate) + xs:dayTimeDuration('PT1M')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$nfInvalidDateTime"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$registerAuthorDate">
				<!-- author/time is normally required, except when a patient has registered medication use him/herself.
          (Author currently contains only a care provider, not the patient.)  -->
				<xsl:value-of select="nf:convertDateTime($registerAuthorDate)"/>
			</xsl:when>
			<xsl:when test="$registerPatientDate">
				<!-- a patient has registered medication use him/herself -->
				<xsl:value-of select="nf:convertDateTime($registerPatientDate)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$nfInvalidDateTime"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>


	<xd:doc>
		<xd:desc>
			<xd:p>Returns the start date (and time) of the most recent component of the specified
        type.</xd:p>
			<xd:p>(Note: this is later used to find the most recent node by comparing the start
          dates. Perhaps not the most elegant way to get the node, so this could be reworked
          later.)</xd:p>
		</xd:desc>

		<xd:param name="componentNode">
			<xd:p>The root of the component ('substanceAdministration').</xd:p>
		</xd:param>
		<xd:param name="componentType">
			<xd:p>The type of the component we're looking for ('ma', 'ta' or 'gb').</xd:p>
		</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineMostRecentComponent" as="xs:dateTime?">
		<xsl:param name="componentType" as="xs:decimal"/>
		<xsl:param name="componentNode" as="node()*"/>

		<xsl:variable name="mostRecentComponent" as="xs:dateTime*">
			<xsl:choose>
				<xsl:when test="$componentType eq $CT_MA">
					<xsl:for-each select="$componentNode[hl7:templateId/@root = $ma_templateId]">
						<xsl:value-of select="nf:determineStartDateTime(.)"/>
					</xsl:for-each>

				</xsl:when>
				<xsl:when test="$componentType eq $CT_TA">
					<xsl:for-each select="$componentNode[hl7:templateId/@root = $ta_templateId]">
						<xsl:value-of select="nf:determineStartDateTime(.)"/>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="$componentType eq $CT_GB">
					<xsl:for-each select="
							$componentNode[hl7:templateId/@root = $gb_templateId]">
						<xsl:value-of select="nf:determineStartDateTime(.)"/>
					</xsl:for-each>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="count($mostRecentComponent) gt 0">
				<xsl:value-of select="max($mostRecentComponent)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$nfInvalidDateTime"/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:function>


	<xd:doc>
		<xd:desc>
			<xd:p>Returns the start date and time of the group ('medicamenteuze behandeling'). This is the
        oldest dateTime of any component: the MBH starts as soon as the first component takes
        effect. If no valid dateTime is found in any of its components, the function will return
        nfInvalidDateTime.</xd:p>
		</xd:desc>
		<xd:param name="curGroup">the group of components (the MBH).</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineMBHstartDateTime" as="xs:dateTime">
		<xsl:param name="curGroup" as="node()*"/>

		<!-- Loop over all blocks in het MBH and add the most appropriate startDate to a list -->
		<xsl:variable name="mbhStartDates" as="xs:dateTime*">
			<xsl:for-each select="$curGroup">

				<xsl:variable name="componentType" select="nf:determineComponentType(../..)" as="xs:decimal"/>
				<xsl:if test="($componentType eq $CT_MA) or ($componentType eq $CT_TA) or ($componentType eq $CT_GB)">
					<xsl:variable name="startDate" select="../../effectiveTime/low/@value"/>
					<xsl:variable name="registerDate" select="../../author/time/@value"/>
					<xsl:choose>
						<xsl:when test="$startDate">
							<xsl:value-of select="nf:convertDateTime($startDate)"/>
						</xsl:when>
						<xsl:when test="$registerDate">
							<xsl:value-of select="nf:convertDateTime($registerDate)"/>
						</xsl:when>
						<!-- No otherwise: only add available dates to the list -->
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<!-- The startDate of the MBH is the earliest of the startDates in the list; or invalid if no dates found -->
		<xsl:choose>
			<xsl:when test="count($mbhStartDates) gt 0">
				<xsl:value-of select="min($mbhStartDates)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$nfInvalidDateTime"/>
				<!-- Shouldn't happen: author/effectiveTime is required -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xd:doc>
		<xd:desc>Returns if the medication is in use (for MedicatieGebruik)</xd:desc>
		<xd:param name="substAdmNode">substanceAdministration node (root of the component) </xd:param>
	</xd:doc>
	<xsl:function name="nf:MedicationIsInUse" as="xs:boolean">
		<xsl:param name="substAdmNode" as="node()*"/>

		<xsl:choose>
			<!-- MP 9.05 and higher -->
			<xsl:when test="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9189']/value/@value">
				<xsl:value-of select="xs:boolean($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9189']/value/@value)"/>
			</xsl:when>
			<!-- MP 9.04 and earlier -->
			<xsl:when test="$substAdmNode/@negationInd">
				<xsl:value-of select="$substAdmNode/@negationInd = 'false'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="true()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>


	<xd:doc>
		<xd:desc>
			<xd:p>Returns the stop date and time of the group. This is the last stop or end dateTime of
        its most recent MA, TA or GB. (But GB's with no end date won't count, since those are often
        not explicitly stopped.) If the most recent MA or TA is not stopped or ended, or temporarily
        paused, it will return nfFutureDateTime.  (Temporarily paused medication is still active.)
        If no valid end dates are found, nfFutureDateTime is returned.</xd:p>
		</xd:desc>
		<xd:param name="curGroup">The group of components (the MBH).</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineMBHstopDate" as="xs:dateTime">
		<xsl:param name="curGroup" as="node()*"/>

		<xsl:variable name="mostRecentMAdateTime" select="nf:determineMostRecentComponent($CT_MA, $curGroup/../..)" as="xs:dateTime?"/>
		<xsl:variable name="mostRecentTAdateTime" select="nf:determineMostRecentComponent($CT_TA, $curGroup/../..)" as="xs:dateTime?"/>
		<xsl:variable name="mostRecentGBdateTime" select="nf:determineMostRecentComponent($CT_GB, $curGroup/../..)" as="xs:dateTime?"/>

		<xsl:variable name="mostRecentMA" select="$curGroup/../..[nf:determineComponentType(.) eq $CT_MA][nf:determineStartDateTime(.) eq $mostRecentMAdateTime]"/>
		<xsl:variable name="mostRecentTA" select="$curGroup/../..[nf:determineComponentType(.) eq $CT_TA][nf:determineStartDateTime(.) eq $mostRecentTAdateTime]"/>
		<xsl:variable name="mostRecentGB" select="$curGroup/../..[nf:determineComponentType(.) eq $CT_GB][nf:determineStartDateTime(.) eq $mostRecentGBdateTime]"/>

		<xsl:variable name="mbhStopDates" as="xs:dateTime*">
			<!-- only use most recent MA, TA and GB for determining the enddate -->
			<xsl:for-each select="$mostRecentMA | $mostRecentTA | $mostRecentGB">
				<xsl:variable name="componentType" select="nf:determineComponentType(.)" as="xs:decimal"/>

				<xsl:variable name="startDate" select="nf:determineStartDateTime(.)" as="xs:dateTime"/>
				<xsl:variable name="stopDate" select="./effectiveTime/high/@value"/>
				<xsl:variable name="stopType" select="./entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']/value/@code"/>
				<xsl:variable name="durationValue" select="./effectiveTime/width/@value"/>
				<xsl:variable name="durationUnit" select="./effectiveTime/width/@unit"/>

				<!-- Loop over all blocks in the MBH and add the most appropriate stopDate to a list -->
				<xsl:choose>
					<xsl:when test="$stopDate">
						<xsl:choose>
							<!-- if any of the most recent components has a temporary stop, the MBH stays current -->
							<xsl:when test="$stopType = $STOPTYPE_TEMP">
								<xsl:value-of select="$nfFutureDateTime"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="nf:convertDateTime($stopDate)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$durationValue">
						<xsl:value-of select="nf:calculateDateTimePlusDuration($startDate, $durationValue, $durationUnit)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$nfFutureDateTime"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>

			<!-- original code 9.0.3 -->
			<!--	<xsl:for-each select="$curGroup">
				<xsl:variable name="componentType" select="nf:determineComponentType(../..)" as="xs:decimal"/>

				<xsl:variable name="startDate" select="nf:determineStartDateTime(../..)" as="xs:dateTime"/>
				<xsl:variable name="stopDate" select="../../effectiveTime/high/@value"/>
				<xsl:variable name="stopType" select="../../entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']/value/@code"/>
				<xsl:variable name="durationValue" select="../../effectiveTime/width/@value"/>
				<xsl:variable name="durationUnit" select="../../effectiveTime/width/@unit"/>

				<!-\- only use most recent MA, TA and GB with enddate -\->
				<xsl:if test="
						(($componentType eq $CT_MA) and ($startDate eq $mostRecentMAdateTime)) or
						(($componentType eq $CT_TA) and ($startDate eq $mostRecentTAdateTime)) or
						(($componentType eq $CT_GB) and ($startDate eq $mostRecentGBdateTime))">
					<!-\- Loop over all blocks in het MBH and add the most appropriate stopDate to a list -\->
					<xsl:choose>
						<xsl:when test="$stopDate">
							<!-\- Only use stop date if it is a permanent stop, or, for not GB, just ending its duration without a stop -\->
							<xsl:if test="(not($stopType) and ($componentType != $CT_GB)) or $stopType = $STOPTYPE_ABORT">
								<xsl:value-of select="nf:convertDateTime($stopDate)"/>
							</xsl:if>
							<!-\- if any of the most recent components has a temporary stop, the MBH stays current -\->
							<xsl:if test="$stopType = $STOPTYPE_TEMP">
								<xsl:value-of select="$nfFutureDateTime"/>
							</xsl:if>
						</xsl:when>
						<xsl:when test="$durationValue">
							<xsl:value-of select="nf:calculateDateTimePlusDuration($startDate, $durationValue, $durationUnit)"/>
						</xsl:when>
						<xsl:otherwise>
							<!-\- Ignore medication usage that has no enddate -\->
							<!-\- Medication usage will often not explicitly be stopped, and in that case the MBH would always
                   stay visible in the current table. So lets ignore not-stopped usage.
                   But this means that medication that IS still used even though the doctor has stopped it 
                   (esp. 'zo nodig') is not displayed in the current table either.
                   19-12-2017: decided with Gerda that the viewer will the information 'as is', so medication will stay 
                   current until the usage has ended as well.  
                -\->
							<!-\-<xsl:if test="$componentType != $CT_GB">-\->
							<xsl:value-of select="$nfFutureDateTime"/>
							<!-\-</xsl:if>-\->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-\-</xsl:if>-\->
			</xsl:for-each>
	-->
		</xsl:variable>

		<!-- The stopDate of the MBH is the highest of the stopDates in the list -->
		<xsl:choose>
			<xsl:when test="count($mbhStopDates) gt 0">
				<xsl:value-of select="max($mbhStopDates)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$nfFutureDateTime"/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:function>


	<xd:doc>
		<xd:desc>
			<xd:p>Returns the table the group should be displayed in: </xd:p>
			<xd:p>If the MBH start is before now and the end after now, it returns TABLE_CURRENT. </xd:p>
			<xd:p>If the start is after now, but not too far in the future, it returns
        TABLE_FUTURE.</xd:p>
			<xd:p>IF the end is before now, but not too long ago, it returns TABLE_PAST.</xd:p>
			<xd:p>Otherwise it will return TABLE_NONE: MBH's too far in the future or the past are not
        displayed at all.</xd:p>
		</xd:desc>
		<xd:param name="mbhStartDate">The start dateTime of the current group.</xd:param>
		<xd:param name="mbhStopDate">The end dateTime of the current group.</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineMBHtable" as="xs:decimal">
		<xsl:param name="mbhStartDate" as="xs:dateTime"/>
		<xsl:param name="mbhStopDate" as="xs:dateTime"/>

		<xsl:choose>
			<!-- Temporary patch to display old MBH's for 12 months instead of 2:
           currently many test messages get outdated too quickly. 
        -->
			<!-- if stop is more than 2 months before now: don't show -->
			<xsl:when test="
					$mbhStopDate ne $nfFutureDateTime and
					$mbhStopDate lt current-dateTime() - xs:yearMonthDuration('P12M')">
				<xsl:value-of select="$TABLE_NONE"/>
			</xsl:when>

			<!-- Temporary patch to display old MBH's for 12 months instead of 2:
           currently many test messages get outdated too quickly. 
        -->
			<!-- if stop is before now but less than 2 months before now: show as recently stopped -->
			<xsl:when test="
					$mbhStopDate ne $nfInvalidDateTime and
					$mbhStopDate lt current-dateTime() and
					$mbhStopDate gt current-dateTime() - xs:yearMonthDuration('P12M')">
				<xsl:value-of select="$TABLE_PAST"/>
			</xsl:when>

			<!-- if start is more than 3 months after now: don't show -->
			<xsl:when test="
					$mbhStartDate ne $nfInvalidDateTime and
					$mbhStartDate gt current-dateTime() + xs:yearMonthDuration('P3M')">
				<xsl:value-of select="$TABLE_NONE"/>
			</xsl:when>

			<!-- if start is later than now but less than 3 months after now: show as future -->
			<xsl:when test="
					$mbhStartDate ne $nfInvalidDateTime and
					$mbhStartDate gt current-dateTime() and
					$mbhStartDate lt current-dateTime() + xs:yearMonthDuration('P3M')">
				<xsl:value-of select="$TABLE_FUTURE"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$TABLE_CURRENT"/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:function>


	<xd:doc>
		<xd:desc>Create the table header row.</xd:desc>
		<xd:param name="tableType">The table type (current, future or past). (Currently not
      used.)</xd:param>
	</xd:doc>
	<xsl:template name="createTableHeader">
		<xsl:param name="tableType" as="xs:decimal"/>
		<tr>
			<th width="3%"/>
			<!-- collapse MBH button row -->
			<th width="3%"/>
			<!-- collapse Type button row -->
			<th width="3%">
				<xsl:value-of select="nf:getLocalizedString('type')"/>
			</th>
			<th width="16%">
				<xsl:value-of select="nf:getLocalizedString('medication')"/>
			</th>
			<th width="10%">
				<xsl:value-of select="nf:getLocalizedString('startDate')"/>
			</th>
			<th width="10%">
				<xsl:value-of select="nf:getLocalizedString('endDate')"/> /
        <xsl:value-of select="nf:getLocalizedString('duration')"/>
			</th>
			<th width="18%">
				<xsl:value-of select="nf:getLocalizedString('dosage')"/>
			</th>
			<th width="8%">
				<xsl:value-of select="nf:getLocalizedString('route')"/>
			</th>
			<th width="12%">
				<xsl:value-of select="nf:getLocalizedString('reason')"/>
			</th>
			<th width="12%">
				<xsl:value-of select="nf:getLocalizedString('remark')"/>
			</th>
			<th width="8%">
				<xsl:value-of select="nf:getLocalizedString('source')"/>
			</th>
		</tr>
	</xsl:template>


	<xd:doc>
		<xd:desc>Add table lines for all components of the given group (MBH), grouped by component
      type (order: ma, ta, gb), with the most recent on top and the history not visible
      (collapsed).</xd:desc>
		<xd:param name="curContext">The current location in the document. Because of wildcards the exact
      location is not really relevant, as long as it is higher than substanceAdministration
      level.</xd:param>
		<xd:param name="curMBH">The current group (MBH).</xd:param>
	</xd:doc>
	<xsl:template name="DisplayMBH">
		<xsl:param name="curContext"/>
		<xsl:param name="curMBH"/>

		<xsl:variable name="mbhId" select="@id"/>
		<xsl:variable name="mbhContent" select="$curContext//*[*/*[hl7:id/concat(@root, '#', @extension) = $mbhId]][not(hl7:statusCode/@code = 'nullified')]"/>

		<!-- For debug info add a row above the components of 1 MBH with details on that MBH  -->
		<tr bgcolor="#EEEEEE" id="debugInfo" class="hideDebugInfo">
			<td/>
			<td/>
			<td>MBH</td>
			<td>
				<xsl:value-of select="@id"/>
			</td>
			<td>
				<xsl:value-of select="
						if (xs:dateTime(@startdatum) != $nfInvalidDateTime) then
							@startdatum
						else
							''"/>
			</td>
			<td>
				<xsl:value-of select="
						if (xs:dateTime(@stopdatum) != $nfFutureDateTime) then
							@stopdatum
						else
							''"/>
			</td>
			<td colspan="6"/>
		</tr>

		<xsl:variable name="nrComponentsOfMBH" select="count(($mbhContent))"/>
		<xsl:variable name="mostRecentMAdateTime" select="nf:determineMostRecentComponent($CT_MA, $mbhContent)" as="xs:dateTime?"/>
		<xsl:variable name="mostRecentTAdateTime" select="nf:determineMostRecentComponent($CT_TA, $mbhContent)" as="xs:dateTime?"/>
		<xsl:variable name="mostRecentGBdateTime" select="nf:determineMostRecentComponent($CT_GB, $mbhContent)" as="xs:dateTime?"/>
		<xsl:variable name="firstComponentType" select="
				if ($mostRecentMAdateTime ne $nfInvalidDateTime) then
					$CT_MA
				else
					if ($mostRecentTAdateTime ne $nfInvalidDateTime) then
						$CT_TA
					else
						$CT_GB"/>

		<!-- Display all MA's, except those that are nullified -->
		<xsl:variable name="MAofMBH" select="$mbhContent[hl7:templateId[@root = $ma_templateId] and not(hl7:statusCode[@code = 'nullified'])]"/>
		<xsl:for-each select="$MAofMBH">
			<xsl:sort select="nf:determineStartDateTime(.)" order="descending"/>
			<xsl:call-template name="displayComponent">
				<xsl:with-param name="curMBHid" select="$curMBH"/>
				<xsl:with-param name="nrComponentsOfMBH" select="$nrComponentsOfMBH"/>
				<xsl:with-param name="nrComponentsOfType" select="count($MAofMBH)"/>
				<xsl:with-param name="isFirstComponentOfMBH" select="($firstComponentType eq $CT_MA) and (position() eq 1)"/>
				<xsl:with-param name="isFirstComponentOfType" select="position() eq 1"/>
				<xsl:with-param name="substAdmNode" select="."/>
			</xsl:call-template>
		</xsl:for-each>

		<!-- Display all TA's, except those that are nullified -->
		<xsl:variable name="TAofMBH" select="$mbhContent[hl7:templateId[@root = $ta_templateId] and not(hl7:statusCode[@code = 'nullified'])]"/>
		<xsl:for-each select="$TAofMBH">
			<xsl:sort select="nf:determineStartDateTime(.)" order="descending"/>
			<xsl:call-template name="displayComponent">
				<xsl:with-param name="curMBHid" select="$curMBH"/>
				<xsl:with-param name="nrComponentsOfMBH" select="$nrComponentsOfMBH"/>
				<xsl:with-param name="nrComponentsOfType" select="count($TAofMBH)"/>
				<xsl:with-param name="isFirstComponentOfMBH" select="($firstComponentType eq $CT_TA) and (position() eq 1)"/>
				<xsl:with-param name="isFirstComponentOfType" select="position() eq 1"/>
				<xsl:with-param name="substAdmNode" select="."/>
			</xsl:call-template>
		</xsl:for-each>

		<!-- Display all GB's (including those with 'gebruikIndicator = Nee') -->
		<xsl:variable name="GBofMBH" select="$mbhContent[hl7:templateId[@root = $gb_templateId]]"/>
		<xsl:for-each select="$GBofMBH">
			<xsl:sort select="nf:determineStartDateTime(.)" order="descending"/>
			<xsl:call-template name="displayComponent">
				<xsl:with-param name="curMBHid" select="$curMBH"/>
				<xsl:with-param name="nrComponentsOfMBH" select="$nrComponentsOfMBH"/>
				<xsl:with-param name="nrComponentsOfType" select="count($GBofMBH)"/>
				<xsl:with-param name="isFirstComponentOfMBH" select="($firstComponentType eq $CT_GB) and (position() eq 1)"/>
				<xsl:with-param name="isFirstComponentOfType" select="position() eq 1"/>
				<xsl:with-param name="substAdmNode" select="."/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>


	<xd:doc>
		<xd:desc>Creates a table line with the important properties of the component
      ('bouwsteen').
    </xd:desc>
		<xd:param name="curMBHid">The ID of the MBH that this component is part of. (Used for the
      collapse/expand functionality.)</xd:param>
		<xd:param name="nrComponentsOfMBH">The number of components in the group (MBH). Used for
      displaying the MBH collapse/expand button.</xd:param>
		<xd:param name="nrComponentsOfType">The number of components of the MBH with the same type as
      the current component. Used for displaying the component type collapse/expand
      button.</xd:param>
		<xd:param name="isFirstComponentOfMBH">True if the component is the first component of the MBH
      to be displayed.</xd:param>
		<xd:param name="isFirstComponentOfType">True if the component is the first component of the type
      to be displayed.</xd:param>
		<xd:param name="substAdmNode">The SubstanceAdministration node of the current component</xd:param>
	</xd:doc>
	<xsl:template name="displayComponent">
		<xsl:param name="curMBHid" as="xs:string"/>
		<xsl:param name="nrComponentsOfMBH" as="xs:decimal"/>
		<xsl:param name="nrComponentsOfType" as="xs:decimal"/>
		<xsl:param name="isFirstComponentOfMBH" as="xs:boolean"/>
		<xsl:param name="isFirstComponentOfType" as="xs:boolean"/>
		<xsl:param name="substAdmNode" as="node()"/>


		<xsl:variable name="componentType" select="nf:determineComponentType(.)"/>
		<xsl:variable name="isStop" as="xs:boolean" select="
				exists($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']) or
				not(nf:MedicationIsInUse($substAdmNode))"/>
		<!-- if there is a stoptype, or medication in use indicator is false -->

		<xsl:variable name="isDeviatingGB" as="xs:boolean" select="
				if (exists($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9117'])) then
					($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9117']/value/@value eq 'false')
				else
					false()"/>
		<tr class="{$curMBHid}" id="{$componentType}">
			<!-- if the component is not the first of the MBH: collapse the row -->
			<xsl:attribute name="style">
				<xsl:if test="not($isFirstComponentOfMBH)">display:none</xsl:if>
				<xsl:if test="$isStop">; color:darkgray</xsl:if>
				<xsl:if test="$isDeviatingGB">; color:blue</xsl:if>
			</xsl:attribute>

			<td style="text-align:center; font-weight:bold">
				<!-- if the component is the first of a MBH with multiple components: show the expand/collapse button -->
				<xsl:if test="($nrComponentsOfMBH gt 1)">
					<xsl:choose>
						<xsl:when test="$isFirstComponentOfMBH">
							<button style="width:28px" onclick="ToggleMBH(this)">
								<!--  <!-\- Show that one or more of the collapsed lines deviate from the MA -/->
                <xsl:attribute name="style">
                  <xsl:if test="$hasDeviatingComponent">; background-color:lightblue</xsl:if>
                </xsl:attribute>
                -->
                +
              </button>
							<!-- Alternative look using hyperlink instead of button -->
							<!--<a onclick="ToggleMBH(this)" style="cursor:pointer"><b>+</b></a>-->

							<!-- E.g. for debugging: show the the number of components that are collapsed -->
							<!--(<xsl:value-of select="$nrComponentsOfMBH"/>)-->
						</xsl:when>
						<xsl:otherwise>
							<!-- Show that the other components in the MBH are part of the set --> └
            </xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</td>
			<td style="text-align:center; font-weight:bold">
				<!-- if the component is the first of a MBH with multiple components: show the expand/collapse button -->
				<xsl:if test="($nrComponentsOfType gt 1)">
					<xsl:choose>
						<xsl:when test="$isFirstComponentOfType">
							<button style="width:28px; display:none" onclick="ToggleID(this)">
								<!--  <!-\- Show that one or more of the collapsed lines deviate from the MA -/->
                  <xsl:attribute name="style">
                    <xsl:if test="$hasDeviatingComponent">; background-color:lightblue</xsl:if>
                  </xsl:attribute>
                -->
                +
              </button>

							<!-- Alternative look using linke instead of button -->
							<!--<a onclick="ToggleID(this)" style="cursor:pointer; display:none"><b>+</b></a>-->

							<!-- E.g. for debugging: show the the number of components that are collapsed -->
							<!--(<xsl:value-of select="$nrComponentsOfType"/>)-->
						</xsl:when>
						<xsl:otherwise>
							<!-- Show that the other components in the MBH are part of the set --> └
            </xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</td>
			<td>
				<!-- Show type of component -->
				<center>
					<xsl:call-template name="getComponentTypeIcon">
						<xsl:with-param name="componentType" select="$componentType"/>
					</xsl:call-template>
				</center>
			</td>
			<td>
				<xsl:call-template name="getMedicationName">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
				<xsl:call-template name="showReferences">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationStartDate">
					<xsl:with-param name="componentType" select="$componentType"/>
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationEndDateOrDuration">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationDosage">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationRoute">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationReason">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationRemark">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:call-template name="getMedicationAuthor">
					<xsl:with-param name="substAdmNode" select="$substAdmNode"/>
				</xsl:call-template>
			</td>
		</tr>
	</xsl:template>

	<xd:doc>
		<xd:desc>Returns the component type of the current component (MA, TA or GB).</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:function name="nf:determineComponentType" as="xs:decimal">
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:variable name="componentType">
			<xsl:choose>
				<xsl:when test="$substAdmNode/templateId/@root = $ma_templateId">
					<xsl:value-of select="$CT_MA"/>
				</xsl:when>
				<xsl:when test="$substAdmNode/templateId/@root = $ta_templateId">
					<xsl:value-of select="$CT_TA"/>
				</xsl:when>
				<xsl:when test="$substAdmNode/templateId/@root = $gb_templateId">
					<xsl:value-of select="$CT_GB"/>
				</xsl:when>
				<!-- We're not really interested in supply components here, so just throw them on a big heap. -->
				<xsl:when test="$substAdmNode/supply">
					<xsl:value-of select="$CT_SUPPLY"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$CT_UNKNOWN"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$componentType"/>
	</xsl:function>

	<xd:doc>
		<xd:desc>Returns html for displaying the icon (or text) that represents the component
      type.</xd:desc>
		<xd:param name="componentType">MA, TA or GB</xd:param>
	</xd:doc>
	<xsl:template name="getComponentTypeIcon">
		<xsl:param name="componentType" as="xs:decimal"/>

		<xsl:choose>
			<xsl:when test="$componentType eq $CT_MA">
				<img src="{$ImagedataIconCareProvider}" title="{nf:getLocalizedString('medicationAgreement')}"/>
			</xsl:when>
			<xsl:when test="$componentType eq $CT_TA">
				<img src="{$ImagedataIconPharmacist}" title="{nf:getLocalizedString('administrationAgreement')}"/>
			</xsl:when>
			<xsl:when test="$componentType eq $CT_GB">
				<img src="{$ImagedataIconPatient}" title="{nf:getLocalizedString('medicationUse')}"/>
				<xsl:if test="not(nf:MedicationIsInUse(.))">
					<!-- Medication not in use -->
					<img src="{$ImagedataIconStop}" title="Niet gebruikt"/>

				</xsl:if>
			</xsl:when>
			<xsl:when test="$componentType eq $CT_SUPPLY">SPLY</xsl:when>
			<xsl:when test="$componentType eq $CT_UNKNOWN">??</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xd:doc>
		<xd:desc>Returns the medication name of the component in the current context.</xd:desc>
		<xd:param name="substAdmNode"/>
	</xd:doc>
	<xsl:template name="getMedicationName">
		<xsl:param name="substAdmNode" as="node()"/>

		<!-- Since either the G-standard code, or the name (for composite = 'magistraal') is filled, 
         just display both and the relevant one will appear. -->
		<xsl:value-of select="$substAdmNode/consumable/manufacturedProduct/manufacturedMaterial/code/@displayName"/>
		<xsl:value-of select="$substAdmNode/consumable/manufacturedProduct/manufacturedMaterial/name"/>

		<div id="debugInfo" class="hideDebugInfo">
			<xsl:if test="$substAdmNode/consumable/manufacturedProduct/manufacturedMaterial/pharm:desc">
				<br/>
			</xsl:if>
			<xsl:value-of select="$substAdmNode/consumable/manufacturedProduct/manufacturedMaterial/pharm:desc"/>
		</div>
	</xsl:template>


	<xd:doc>
		<xd:desc>
      Displays an icon if a reference is present to either MA, TA or GB outside the own MBH. 
      The tooltip shows the medication name of the referred component.
    </xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="showReferences">
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:variable name="curMBHid" select="
				concat($substAdmNode/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@root,
				$substAdmNode/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@extension)"/>

		<!-- Relation to MA -->
		<xsl:for-each select="$substAdmNode/entryRelationship[@typeCode = 'REFR']/substanceAdministration[./templateId/@root eq '2.16.840.1.113883.2.4.3.11.60.20.77.10.9086']">
			<xsl:variable name="refRoot" select="./id/@root" as="xs:string?"/>
			<xsl:variable name="refExt" select="./id/@extension" as="xs:string?"/>
			<xsl:variable name="referredMA" select="../../../../component/substanceAdministration[id/@root eq $refRoot and id/@extension eq $refExt]"/>
			<!-- In case more than one MA has the same ID: use [1] -->
			<xsl:variable name="refMBHid" select="
					concat($referredMA[1]/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@root,
					$referredMA[1]/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@extension)"/>
			<xsl:variable name="refTitle">
				<xsl:value-of select="$referredMA/consumable/manufacturedProduct/manufacturedMaterial/code/@displayName"/>
				<xsl:value-of select="$referredMA/consumable/manufacturedProduct/manufacturedMaterial/name"/>
			</xsl:variable>

			<xsl:if test="$referredMA and ($curMBHid ne $refMBHid)">
				<xsl:text> </xsl:text>
				<img src="{$ImagedataIconRefCareProvider}" title="relatie naar MA: {$refTitle}"/>
			</xsl:if>
		</xsl:for-each>

		<!-- Relation to TA -->
		<xsl:for-each select="$substAdmNode/entryRelationship[@typeCode = 'REFR']/substanceAdministration[./templateId/@root eq '2.16.840.1.113883.2.4.3.11.60.20.77.10.9101']">
			<xsl:variable name="refRoot" select="./id/@root" as="xs:string"/>
			<xsl:variable name="refExt" select="./id/@extension" as="xs:string"/>
			<xsl:variable name="referredTA" select="../../../../component/substanceAdministration[id/@root eq $refRoot and id/@extension eq $refExt]"/>
			<!-- In case more than one TA has the same ID: use [1] -->
			<xsl:variable name="refMBHid" select="
					concat($referredTA[1]/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@root,
					$referredTA[1]/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@extension)"/>
			<xsl:variable name="refTitle">
				<xsl:value-of select="$referredTA/consumable/manufacturedProduct/manufacturedMaterial/code/@displayName"/>
				<xsl:value-of select="$referredTA/consumable/manufacturedProduct/manufacturedMaterial/name"/>
			</xsl:variable>

			<xsl:if test="$referredTA and ($curMBHid ne $refMBHid)">
				<xsl:text> </xsl:text>
				<img src="{$ImagedataIconRefPharmacist}" title="relatie naar TA: {$refTitle}"/>
			</xsl:if>
		</xsl:for-each>

		<!-- Relation to GB -->
		<xsl:for-each select="$substAdmNode/entryRelationship[@typeCode = 'REFR']/substanceAdministration[./templateId/@root eq '2.16.840.1.113883.2.4.3.11.60.20.77.10.9176']">
			<xsl:variable name="refRoot" select="./id/@root" as="xs:string"/>
			<xsl:variable name="refExt" select="./id/@extension" as="xs:string"/>
			<xsl:variable name="referredGB" select="../../../../component/substanceAdministration[id/@root eq $refRoot and id/@extension eq $refExt]"/>
			<!-- In case more than one GB has the same ID: use [1] -->
			<xsl:variable name="refMBHid" select="
					concat($referredGB[1]/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@root,
					$referredGB[1]/entryRelationship/procedure[templateId[@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9084']]/id/@extension)"/>
			<xsl:variable name="refTitle">
				<xsl:value-of select="$referredGB/consumable/manufacturedProduct/manufacturedMaterial/code/@displayName"/>
				<xsl:value-of select="$referredGB/consumable/manufacturedProduct/manufacturedMaterial/name"/>
			</xsl:variable>

			<xsl:if test="$referredGB and ($curMBHid ne $refMBHid)">
				<xsl:text> </xsl:text>
				<img src="{$ImagedataIconRefPatient}" title="relatie naar GB: {$refTitle}"/>
			</xsl:if>
		</xsl:for-each>

	</xsl:template>


	<xd:doc>
		<xd:desc>Returns the start date of the component in the current context. If no start date is
      specified, it shows the registration date with corresponding icon.</xd:desc>
		<xd:param name="componentType">MA, TA or GB</xd:param>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationStartDate">
		<xsl:param name="componentType"/>
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:variable name="registerAuthorDate" select="$substAdmNode/author/time/@value"/>
		<xsl:variable name="tooltip">
			<xsl:choose>
				<xsl:when test="$componentType eq $CT_GB">
					<xsl:value-of select="nf:getLocalizedString('registrationDate')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="nf:getLocalizedString('agreementDate')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Pre 9.04 compatibility -->
		<xsl:variable name="registerPatientDate" select="$substAdmNode/participant[@typeCode = 'AUT' and participantRole/@classCode = 'PAT']/time/@value"/>

		<xsl:choose>
			<xsl:when test="$substAdmNode/effectiveTime/@value">
				<xsl:value-of select="nf:printHl7DateTime($substAdmNode/effectiveTime/@value, true())"/>
			</xsl:when>
			<xsl:when test="$substAdmNode/effectiveTime/low">
				<xsl:value-of select="nf:printHl7DateTime($substAdmNode/effectiveTime/low/@value, true())"/>
			</xsl:when>
			<xsl:when test="$registerAuthorDate">
				<!-- Always show the registration date if the start date is not specified -->
				<img src="{$ImagedataIconPrescribe}" height="16px" title="{$tooltip}"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="nf:printHl7DateTime($registerAuthorDate, true())"/>
			</xsl:when>
			<!-- Pre 9.04 compatibility -->
			<xsl:when test="$registerPatientDate">
				<!-- Always show the registration date if the start date is not specified -->
				<img src="{$ImagedataIconPrescribe}" height="16px" title="{nf:getLocalizedString('registrationDate')}"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="nf:printHl7DateTime($registerPatientDate, true())"/>
			</xsl:when>
		</xsl:choose>

		<!-- For debugging: always show registration date too -->
		<div id="debugInfo" class="hideDebugInfo">
			<!-- if not already shown -->
			<xsl:if test="$substAdmNode/effectiveTime/@value or $substAdmNode/effectiveTime/low">
				<xsl:if test="$registerAuthorDate">
					<!-- Always show the registration date if the start date is not specified -->
					<img src="{$ImagedataIconPrescribe}" height="16px" title="{$tooltip}"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="nf:printHl7DateTime($registerAuthorDate, true())"/>
				</xsl:if>
				<!-- Pre 9.04 compatibility -->
				<xsl:if test="$registerPatientDate">
					<!-- Always show the registration date if the start date is not specified -->
					<img src="{$ImagedataIconPrescribe}" height="16px" title="{nf:getLocalizedString('registrationDate')}"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="nf:printHl7DateTime($registerPatientDate, true())"/>
				</xsl:if>
			</xsl:if>
		</div>
	</xsl:template>


	<xd:doc>
		<xd:desc>Returns the end date, or if not specified the duration (+unit) of the component in the
      current context.</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationEndDateOrDuration">
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:choose>
			<xsl:when test="$substAdmNode/effectiveTime/high">
				<xsl:value-of select="nf:printHl7DateTime($substAdmNode/effectiveTime/high/@value, true())"/>
			</xsl:when>
			<xsl:when test="$substAdmNode/effectiveTime/width">
				<xsl:value-of select="concat($substAdmNode/effectiveTime/width/@value, ' ', $substAdmNode/effectiveTime/width/@unit)"/>
			</xsl:when>

			<!-- otherwise: just leave empty -->
		</xsl:choose>
	</xsl:template>

	<xd:doc>
		<xd:desc>Returns the dosage instructions of the component in the current context.</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationDosage">
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:value-of select="$substAdmNode/hl7:text"/>

		<!-- If additional information is shown, also show the 'aanvullende instructie's -->
		<div id="debugInfo" class="hideDebugInfo">
			<xsl:for-each select="$substAdmNode/entryRelationship/act[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9085']">
				<br/>
				<xsl:value-of select="./code/originalText"/>
			</xsl:for-each>
		</div>
	</xsl:template>

	<xd:doc>
		<xd:desc>Returns the route ('toedieningsweg') of the component in the current context.</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationRoute">
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:value-of select="$substAdmNode/routeCode/@displayName"/>
	</xsl:template>

	<xd:doc>
		<xd:desc>Returns the reason(s) for the component in the current context. This can contain the
      reason for prescribing, the reason for a pause, and/or the reason for aborting the
      prescription/administration/use.</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationReason">
		<xsl:param name="substAdmNode" as="node()"/>

		<!-- Reden van Voorschrijven (MA) -->
		<xsl:if test="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9160']">
			<img src="{$ImagedataIconPrescribe}" height="16px" title="{nf:getLocalizedString('prescriptionReason')}"/>
			<xsl:text> </xsl:text>
			<!--Voorschrijven:-->
			<!-- 'reden van voorschrijven' can appear in 2 places -->
			<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9160']/value/@displayName"/>
			<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9160']/value/originalText"/>
		</xsl:if>

		<!-- If additional information is shown, also show TA 'Reden afspraak', unless it is a stop - then that reason is already shown below -->
		<div id="debugInfo" class="hideDebugInfo">
			<xsl:if test="not(exists($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']))">
				<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9083']/text"/>
			</xsl:if>
		</div>

		<!-- Reden van Gebruik (GB) -->
		<xsl:if test="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9114']">
			<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9114']/text"/>
		</xsl:if>

		<xsl:if test="
				$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9160'] and
				$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']">
			<br/>
		</xsl:if>
		<!-- 'reden van staken': found in 'reden van afspraak' different locations for ma, ta and gb. -->
		<xsl:if test="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']">
			<xsl:variable name="stopType" select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067']/value/@code" as="xs:decimal?"/>

			<xsl:choose>
				<xsl:when test="$stopType eq $STOPTYPE_TEMP">
					<img src="{$ImagedataIconTempStop}" height="16px" title="{nf:getLocalizedString('pauseReason')}"/>
				</xsl:when>
				<xsl:otherwise>
					<img src="{$ImagedataIconStop}" height="16px" title="{nf:getLocalizedString('abortReason')}"/>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:text> </xsl:text>
			<!-- Whitespace between icon and text -->
			<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9068']/value/@displayName"/>
			<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9083']/text"/>
			<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9115']/value/@displayName"/>
		</xsl:if>


		<!-- reden stoppen/wijzigen gebruik -->
		<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9115']/value/@displayName"/>

	</xsl:template>


	<xd:doc>
		<xd:desc>Returns the remark and/or the additional information of the component in the current
      context.</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationRemark">
		<xsl:param name="substAdmNode" as="node()"/>

		<!-- 'Toelichting' -->
		<xsl:value-of select="$substAdmNode/entryRelationship/act[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9069']/text"/>

		<!-- Add a line break if both values are present  -->
		<xsl:if test="
				exists($substAdmNode/entryRelationship/act[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9069']) and
				exists($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9177'])">
			<br/>
		</xsl:if>

		<!-- 'Aanvullende Informatie' -->
		<xsl:value-of select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9177']/value/@displayName"/>

		<!-- Gerda decided 'Reden van afspraak' will usually not be filled, and showing it night cause confusion, so it is not displayed  
   <!-\- Display 'Reden van afspraak' unless it is a Stop - then the reason is already displayed in 'Reason' -\->
    <xsl:if
      test="not($substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9067'])">
      <!-\- Add a line break if necessary -\->
      <xsl:if test="(exists($substAdmNode/entryRelationship/act[templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9069']) or
        exists($substAdmNode/entryRelationship/observation[templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9177'])) and 
        exists($substAdmNode/entryRelationship/observation[templateId/@root='2.16.840.1.113883.2.4.3.11.60.20.77.10.9183'])">
        <br />
      </xsl:if>      
      <xsl:value-of
        select="$substAdmNode/entryRelationship/observation[templateId/@root = '2.16.840.1.113883.2.4.3.11.60.20.77.10.9083']/text"/>
    </xsl:if>
-->

	</xsl:template>


	<xd:doc>
		<xd:desc>Returns the author of the component in the current context. In case of a care provider its
      role is also shown. In case of a patient only the text 'patient' is displayed.</xd:desc>
		<xd:param name="substAdmNode">The location of the component in the document, at substanceAdministration level.</xd:param>
	</xd:doc>
	<xsl:template name="getMedicationAuthor">
		<xsl:param name="substAdmNode" as="node()"/>

		<xsl:choose>
			<!-- Author is care provider -->
			<xsl:when test="$substAdmNode/author/assignedAuthor/assignedPerson">
				<xsl:call-template name="util:show-name">
					<xsl:with-param name="in" select="$substAdmNode/author/assignedAuthor/assignedPerson/name"/>
				</xsl:call-template>

				<!-- Add the care provider role -->
				<xsl:value-of select="
						if ($substAdmNode/author/assignedAuthor/code) then
							concat(' (', $substAdmNode/author/assignedAuthor/code/@displayName, ')')
						else
							''"/>
			</xsl:when>

			<!-- Author is organization - as with TA -->
			<xsl:when test="$substAdmNode/author/assignedAuthor/representedOrganization">
				<xsl:value-of select="$substAdmNode/author/assignedAuthor/representedOrganization/name"/>
			</xsl:when>

			<!-- Author is Patient (should not occur simultaneously with care provider author -->
			<!-- Publication 9.04 -->
			<xsl:when test="$substAdmNode/author/assignedAuthor/code/@code eq 'ONESELF'">
				<xsl:value-of select="nf:getLocalizedString('recordTarget')"/>
			</xsl:when>
			<!-- Publication 9.03 backwards compatibility -->
			<xsl:when test="$substAdmNode/participant[@typeCode = 'AUT' and $substAdmNode/participantRole/@classCode = 'PAT']">
				<xsl:value-of select="nf:getLocalizedString('recordTarget')"/>
			</xsl:when>

		</xsl:choose>

	</xsl:template>
</xsl:stylesheet>
