Need a utility Google Sheet worksheet to be generated like the following.
Sheet to be created through a Code.gs.js function prepareManufacturerMaterialInputSheet()

Logic of prepareManufacturerMaterialInputSheet() function
    create new sheet with sheet Name: MaintainManufacturerMaterial
    cell(1, 1) to Cell (1, 5) - Maintain Manucaturer Materials Models (folt 14 bold as title) - merge cells
    cell(2, 1): Manufacturer (Label font 12 bold)
    cell(2, 2): Manufacturer drop-down values of Manufacturer Names - with link to manufacturers sheet for drop down values
    Cell(3, 1): Prepare Input Table (link to function prepareManufacturerMaterialInputData)
    Cell(3, 2): Maintain link to function prepareManufacturerMaterialInputData

    cell(4, 1): Material (label font 12 bold)
    cell(4, 2): Model 1 (label font 12 bold)
    cell(4, 3): Model 2 (label font 12 bold)
    cell(4, 4): Model 3 (label font 12 bold)
    cell(4, 5): Model 4 (label font 12 bold)
    cell(4, 6): Model 5 (label font 12 bold)
    cell(4, 7): Model 6 (label font 12 bold)
    cell(4, 8): Model 7 (label font 12 bold)
    cell(4, 9): Model 8 (label font 12 bold)
    cell(4, 10): Model 9 (label font 12 bold)
    cell(4, 11): Model 10 (label font 12 bold)

Code.gs.js function prepareManufacturerMaterialInputData() logic
    select all material uuid, name from materials sheet - array mat[]
    select all material_id, material_name, model manufactuer_materials for given manufacturer in cell (2,2) - array mm[]
    sort array mm[] by material_name, model

    Prepare the matrix below
    Iterate through mat (index i)
    cell(i+4+1, 1): Material Name 
    c = 1
    Iterate through array mm (index j)
        if mm[j].material_name = mat[i].material_name
        c = c + 1
        cell(i+4+1,c): md.model

Now User enters model values in cells (4+1,2) through available records below.

When user presses maintain link in cell(3,2) function prepareManufacturerMaterialInputData gets invoke

prepareManufacturerMaterialInputData logic should be as follows.

    read materials sheet and prepare materials_map as {
        "material name value": "material uuid value"
    }
    read manufacturers sheet and prepare manufacturers_map as {
        "manufacturer name value": "manufacturer uuid value"
    }
    manufacturer_id = manufacturers_map[cell(2, 2)]

    read manufacturer_materials sheet for manufacturer_id and prepare models_map as {
        "material_id value": {
            "model value": "uuid value"
        }
    }

    mmm = [];
    mmmInsert = [];
    mmmDelete = [];
    mmMap = {};
    Iterate through sheet rows from row 5 - current row r
        iterate throughs columns on row r, from 2 to 10 - current column c
            if cells(r, c) is not empty
                mmmRec = {}
                mmmRec.manufacturer_name = Cell(2, 2)
                mmmRec.manufacturer_id = manufacturers_map[mmmRec.manufacturer_name]
                mmmRec.material_name = cells(r, 1)
                mmmRec.material_id = materials_map[mmmRec.material_name]
                mmmRec.model = cells(r, c)
                mmmRec.uuid = models_map[mmmRec.material_id][mmmRec.model]
                if mmmRec.uuuid is not valid value
                    mmmRec.uuid = UUID( ) //new uuid
                    mmmRec.newEntry = true
                    append mmmRec to mmmInsert
                append mmmRec to mmm
                mmMap[ mmmRec.uuid ] = mmmRec

    Iterage through member field names in object models_map
        mat_id = member name
        Iterate through members of models_map[mat_id]
            model = member name
            mmmRec = {}
            mmmRec.manufacturer_name = Cell(2, 2)
            mmmRec.manufacturer_id = manufacturers_map[mmmRec.manufacturer_name]
            mmmRec.material_id = mat_id
            mmmRec.model = model
            mmmRec.uuid = models_map[mat_id][model]
            if mmmRec.uuid not in mmMap as member
                mmmRec to mmmDelete
    
    now delete records in sheet manufacturer_materials by criteria
        row.manufacturer_material_id = array members of mmmDelete comparing manufacturer_material_id

    now insert records in sheet manufacturer_materials from mmmInsert for columns
        uuid
        manufacturer_id
        material_id
        model

        



