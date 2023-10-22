### A Pluto.jl notebook ###
# v0.19.29

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ eeba971b-c64e-4195-95ca-5cf2ae5ac590
# ╠═╡ show_logs = false
begin
  using Pkg
  Pkg.activate(".")

  using CairoMakie
  using GLMakie
  using DICOM, PlutoUI, ImageMorphology, Statistics, DataFrames
  using PerfusionImaging
  using FileIO
  using Meshes
  using JLD2
end

# ╔═╡ 0129d839-fde4-46bf-a2e1-beb79fdd2cab
TableOfContents()

# ╔═╡ b4252854-a892-48d1-9c67-4b4ac3b74ded
md"""
# Load DICOMs
"""

# ╔═╡ 6fa28ef7-8e95-43af-9ef1-9fb549590bf7
md"""
## Choose Main Path
"""

# ╔═╡ aa13d033-c4a1-455c-8fa2-5cfc5a51b9c2
md"""
**Enter Root Directory**

Provide the path to the main folder containing the raw DICOM files and segmentations. Then click submit.

$(@bind root_path confirm(PlutoUI.TextField(60; default = "/Users/harryxiong24/Code/Lab/perfusion/heart")))
"""

# ╔═╡ a830eebb-faf8-492b-ac42-2109e5173482
md"""
## V2
"""

# ╔═╡ 2efe5c77-d476-4053-ab8b-47a593735690
function volume_paths(dcm, v1, v2)

  return PlutoUI.combine() do Child

    inputs = [
      md""" $(dcm): $(
      	Child(PlutoUI.TextField(60; default = "DICOM"))
      )""",
      md""" $(v1): $(
      	Child(PlutoUI.TextField(60; default = "01"))
      )""",
      md""" $(v2): $(
      	Child(PlutoUI.TextField(60; default = "02"))
      )""",
    ]

    md"""
    **Upload Volume Scans**

    Provide the folder names for the necessary files. First input the name of the folder containing the DICOM scans (default is `DICOM`) and then enter the names of the v1 and v2 scans (default is `01` and `02`, respectively). Then click submit.

    $(inputs)
    """
  end
end

# ╔═╡ cafb7f62-2bd9-493f-9af9-c4d15a554528
@bind volume_files confirm(volume_paths("Enter DICOM folder name", "Enter volume scan 1 folder name", "Enter volume scan 2 folder name"))

# ╔═╡ c84f0933-8354-4f89-ab16-032cdebb1101
volume_files

# ╔═╡ 26b7a474-0653-4ff4-9455-df1448623fee
dicom_path = joinpath(root_path, volume_files[1])

# ╔═╡ 185d08b1-a1f7-4bf2-b0c3-84af66dcc415
path_v2 = joinpath(dicom_path, volume_files[3])

# ╔═╡ baeb5520-a946-4ce5-9d66-c0407d47cca2
dcms_v2 = dcmdir_parse(path_v2)

# ╔═╡ 82a0af24-d4a9-461b-b054-90fe37fa61e5
md"""
## SureStart
"""

# ╔═╡ 43c9c836-2492-431a-9664-d4f900279b2e
md"""
**Enter SureStart Folder**

Input the name of the folder containing the SureStart scans (default is `SureStart`). Then click submit

$(@bind surestart_folder confirm(PlutoUI.TextField(60; default = "SureStart")))
"""

# ╔═╡ 7f54d3c0-945e-4bc3-b2de-f37d93208963
surestart_path = joinpath(root_path, surestart_folder);

# ╔═╡ 0c7580e8-3e49-44bf-b53e-5070be62e722
dcms_ss = dcmdir_parse(surestart_path);

# ╔═╡ 795e6621-0df8-49e5-973a-ada9b37e451f
md"""
## Segmentations
"""

# ╔═╡ 9e791737-a82f-4b07-b6da-fe8d4af1bfe1
md"""
**Enter Segmentation Root Folder**

Input the name of the folder containing the segmentation(s) (default is `SEGMENT_dcm`). Then click submit

$(@bind segment_folder confirm(PlutoUI.TextField(60; default = "SEGMENT_dcm")))
"""

# ╔═╡ 1aad87c8-82f1-4436-b5db-3b9a9cdfc3cb
segmentation_root = joinpath(root_path, "SEGMENT_dcm")

# ╔═╡ 9d76a68a-d983-41bb-90c8-02853fa5f37f
md"""
### Arata
"""

# ╔═╡ bec6e715-47f9-42b4-9ce7-6df632b8ff54
md"""
**Enter Limb Segmentation Folder**

Input the name of the folder containing the SureStart scans (default is `AORTA_dcm`). Then click submit

$(@bind limb_folder confirm(PlutoUI.TextField(60; default = "AORTA_dcm")))
"""

# ╔═╡ 7111f8f3-ba5f-4a38-9145-97190e68a93e
arata_path = joinpath(segmentation_root, limb_folder)

# ╔═╡ a71a2492-bbd8-4660-93d1-de5eb3f8c681
dcms_arata = dcmdir_parse(arata_path)

# ╔═╡ 0e5ad727-5fd8-4316-abfb-90a6ad93efaa
md"""
### Left Myocardium
"""

# ╔═╡ e132b952-0319-4d34-94a1-6cb4882f5eb1
md"""
**Enter Left Myocardium Segmentation Folder**

Input the name of the folder containing the SureStart scans (default is `LEFT_MYOCARDIUM_dcm`). Then click submit

$(@bind lm_folder confirm(PlutoUI.TextField(60; default = "LEFT_MYOCARDIUM_dcm")))
"""

# ╔═╡ 17522cca-6b42-4900-9622-6fe8b2174dfc
lm_path = joinpath(segmentation_root, lm_folder)

# ╔═╡ 0dd9eb15-d7ec-41de-9b51-871410246076
dcms_lm = dcmdir_parse(lm_path);

# ╔═╡ c660c6ae-3632-4529-b062-b9439e3b3709
md"""
### Right Myocardium
"""

# ╔═╡ b9f940b3-f4b8-429e-b7e9-fb12e0bf09ac
md"""
**Enter Right Myocardium Segmentation Folder**

Input the name of the folder containing the SureStart scans (default is `RIGHT_MYOCARDIUM_dcm`). Then click submit

$(@bind rm_folder confirm(PlutoUI.TextField(60; default = "RIGHT_MYOCARDIUM_dcm")))
"""

# ╔═╡ a8d2b330-78d4-463a-93ee-dd293e50df4b
rm_path = joinpath(segmentation_root, rm_folder)

# ╔═╡ 8165b2fe-f26b-4594-bcd9-383379fcfe9d
dcms_rm = dcmdir_parse(rm_path);

# ╔═╡ d1ab2748-b597-4c3d-8682-2e97a3fba8a0
md"""
## Vessels
"""

# ╔═╡ 70e6df21-9838-4d17-9765-f5bb78f26633
md"""
**Enter Vessels Root Folder**

Input the name of the folder containing the segmentation(s) (default is `VESSELS_dcm`). Then click submit

$(@bind vessels_folder confirm(PlutoUI.TextField(60; default = "VESSELS_dcm")))
"""

# ╔═╡ 48badd5f-c486-40df-bddb-c8885e629336
vessels_root = joinpath(root_path, "VESSELS_dcm")

# ╔═╡ 2c907a9e-efe9-48d4-96e3-866318f657cf
md"""
### LAD
"""

# ╔═╡ e04cf80a-08d5-4ab3-af80-b1cbf4622219
md"""
**Enter Right Myocardium Segmentation Folder**

Input the name of the folder containing the SureStart scans (default is `LAD`). Then click submit

$(@bind lad_folder confirm(PlutoUI.TextField(60; default = "LAD")))
"""

# ╔═╡ 1456a54f-da58-43ae-bbbe-55cd2e4c1fb0
lad_path = joinpath(vessels_root, lad_folder)

# ╔═╡ dcd6620c-2924-49a4-95f8-1067381f4357
dcms_lad = dcmdir_parse(lad_path);

# ╔═╡ 5289fe3f-93f2-4c93-8e84-f18b2bd7abbd
md"""
### LCX
"""

# ╔═╡ 28af079e-9b15-4e68-91f2-f2db66f9d12e
md"""
**Enter Right Myocardium Segmentation Folder**

Input the name of the folder containing the SureStart scans (default is `LCX`). Then click submit

$(@bind lcx_folder confirm(PlutoUI.TextField(60; default = "LCX")))
"""

# ╔═╡ 25a2b22c-00c3-4064-af40-c82e708249db
lcx_path = joinpath(vessels_root, lcx_folder)

# ╔═╡ 421ee721-e661-4fa6-86a8-20eb036bb835
dcms_lcx = dcmdir_parse(lcx_path);

# ╔═╡ 4f570b2e-4351-4657-ad74-583f5decb238
md"""
### RCA
"""

# ╔═╡ 81908744-c519-4442-8b41-95eca9f23cd3
md"""
**Enter Right Myocardium Segmentation Folder**

Input the name of the folder containing the SureStart scans (default is `RCA`). Then click submit

$(@bind rca_folder confirm(PlutoUI.TextField(60; default = "RCA")))
"""

# ╔═╡ 63c3c750-ce4b-4838-af34-5a94b87dff16
rca_path = joinpath(vessels_root, rca_folder)

# ╔═╡ 9f8d5935-67ee-4131-8379-b8bb09b99e7d
dcms_rca = dcmdir_parse(rca_path);

# ╔═╡ d3ca2ccf-961e-4612-bfa3-c61dbc27dcbb
md"""
# Convert DICOMs to Arrays
"""

# ╔═╡ 37a39564-c811-4b64-a76d-6071062757b1
md"""
## V2
"""

# ╔═╡ 25541b4e-7c19-44e2-a5a6-27c0b373ea9a
begin
  v2_arr = load_dcm_array(dcms_v2)
end;

# ╔═╡ 60ef5850-638a-4f89-b2be-63d151e2f690
@bind z_vols PlutoUI.Slider(axes(v2_arr, 3), show_value=true, default=size(v2_arr, 3) ÷ 15)

# ╔═╡ 9a7b1a51-90a2-472d-8809-0bbdee4afa1f
let
  f = Figure(resolution=(1200, 800))
  # ax = CairoMakie.Axis(
  #   f[1, 1],
  #   title="V1 (No Contrast)",
  #   titlesize=40,
  # )
  # heatmap!(v1_arr[:, :, z_vols], colormap=:grays)

  ax = CairoMakie.Axis(
    f[1, 1],
    title="V2 (Contrast)",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_vols], colormap=:grays)
  f
end

# ╔═╡ 9ed4ce81-bcff-4279-b841-24675dc9f128
md"""
## Arata
"""

# ╔═╡ 652ff74c-d8a7-475a-b8cc-3d7ead255226
arata_arr = load_dcm_array(dcms_arata);

# ╔═╡ 7466ea3c-e2ba-4cff-8ca7-5b155508e3c6
begin
  arata_mask = copy(arata_arr)
  replace!(x -> x < -1000 ? 0 : x, arata_mask)
  arata_mask = arata_mask[:, :, end:-1:1]
  arata_mask = arata_mask .!= 0
end;

# ╔═╡ 9a780ac2-e296-4080-8d72-f06d64a7e65f
@bind z_arata PlutoUI.Slider(axes(arata_mask, 3), show_value=true, default=size(arata_mask, 3) ÷ 2)

# ╔═╡ 4afa1c70-3c33-4057-bc5d-f8681a1a1438
let
  f = Figure(resolution=(1200, 800))
  ax = Axis(
    f[1, 1],
    title="Arata Mask",
    titlesize=40,
  )
  heatmap!(arata_mask[:, :, z_arata], colormap=:grays)

  ax = Axis(
    f[1, 2],
    title="Arata Mask Overlayed",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_arata], colormap=:grays)
  heatmap!(arata_mask[:, :, z_arata], colormap=(:jet, 0.3))
  f
end

# ╔═╡ 06e21f58-d074-48ec-895d-1b864f96afde
pts_cartesian = findall(isone, arata_mask)

# ╔═╡ f47640fc-39c3-4649-bfb3-ebffc4ab2503
pts_matrix = getindex.(pts_cartesian, [1 2 3])

# ╔═╡ 2a01a6c8-e4fe-483a-a304-712683abd901
md"""
## SureStart
"""

# ╔═╡ f6965577-c718-4a03-87b6-248818860f7d
ss_arr = load_dcm_array(dcms_ss);

# ╔═╡ 25a72dd0-7435-4aa9-98b0-d8a6f5ea1eed
@bind z_ss PlutoUI.Slider(axes(ss_arr, 3), show_value=true, default=size(ss_arr, 3))

# ╔═╡ 36be9348-d572-4fa5-86e5-6e529f2d7092
let
  f = Figure()
  ax = Axis(
    f[1, 1],
    title="SureStart",
  )
  heatmap!(ss_arr[:, :, z_ss], colormap=:grays)
  f
end

# ╔═╡ a2135aeb-81c2-4ac4-ad62-9409a941c18f
md"""
## Left Myocardium
"""

# ╔═╡ fa9fc2d8-52d8-4fd5-9dfa-7cbff1df40d5
lm_arr = load_dcm_array(dcms_lm);

# ╔═╡ 68435ab7-95d9-4b69-94e7-1941e4788384
begin
  lm_mask = copy(lm_arr)
  replace!(x -> x < -1000 ? 0 : x, lm_mask)
  lm_mask = lm_mask[:, :, end:-1:1]
  lm_mask = lm_mask .!= 0
end;

# ╔═╡ dffbee2b-f904-4ce0-8e7d-acf49e76018d
begin
  lm_mask_erode = zeros(size(lm_mask))
  for i in 1:size(lm_mask, 3)
    lm_mask_erode[:, :, i] = erode(lm_mask[:, :, i])
  end
end

# ╔═╡ f8a45540-37d0-4aa9-8f1b-031e48d3956a
@bind z_lm PlutoUI.Slider(axes(lm_mask, 3), show_value=true, default=size(lm_mask, 3) ÷ 15)

# ╔═╡ f0b631f7-9342-4401-ad2b-6e27e4c733df
let
  f = Figure(resolution=(2200, 2200))
  ax = CairoMakie.Axis(
    f[1, 1],
    title="Left Myocardium",
    titlesize=40,
  )
  heatmap!(lm_mask[:, :, z_lm], colormap=:grays)

  ax = CairoMakie.Axis(
    f[1, 2],
    title="Left Myocardium  Mask Eroded",
    titlesize=40,
  )
  heatmap!(lm_mask_erode[:, :, z_lm], colormap=:grays)

  ax = CairoMakie.Axis(
    f[2, 1],
    title="Left Myocardium Mask Overlayed",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_lm], colormap=:grays)
  heatmap!(lm_mask[:, :, z_lm], colormap=(:jet, 0.3))

  ax = CairoMakie.Axis(
    f[2, 2],
    title="Left Myocardium  Mask Eroded",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_lm], colormap=:grays)
  heatmap!(lm_mask_erode[:, :, z_lm], colormap=(:jet, 0.3))
  f
end

# ╔═╡ dafc07a2-47a6-46e9-a19a-85f8b6dad425
md"""
## Right Myocardium
"""

# ╔═╡ db50e16a-e1c8-4f2d-9189-e62faa318a3d
rm_arr = load_dcm_array(dcms_rm);

# ╔═╡ 75880cc4-6eaf-45cf-becd-fef59e33dcbf
begin
  rm_mask = copy(rm_arr)
  replace!(x -> x < -1000 ? 0 : x, rm_mask)
  rm_mask = rm_mask[:, :, end:-1:1]
  rm_mask = rm_mask .!= 0
end;

# ╔═╡ ffd55e13-0f10-43ca-b1ea-d5de4690884c
begin
  rm_mask_erode = zeros(size(rm_mask))
  for i in 1:size(rm_mask, 3)
    rm_mask_erode[:, :, i] = erode(rm_mask[:, :, i])
  end
end

# ╔═╡ 9d612bd9-6b9c-4633-b7be-2a2069fa49b6
@bind z_rm PlutoUI.Slider(axes(rm_mask, 3), show_value=true, default=size(rm_mask, 3) ÷ 15)

# ╔═╡ bdd45ecf-b8ca-42f2-a172-c378e194fddc
let
  f = Figure(resolution=(2200, 2200))
  ax = CairoMakie.Axis(
    f[1, 1],
    title="Right Myocardium",
    titlesize=40,
  )
  heatmap!(rm_mask[:, :, z_rm], colormap=:grays)

  ax = CairoMakie.Axis(
    f[1, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(rm_mask_erode[:, :, z_rm], colormap=:grays)

  ax = CairoMakie.Axis(
    f[2, 1],
    title="Right Myocardium Mask Overlayed",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_rm], colormap=:grays)
  heatmap!(rm_mask[:, :, z_rm], colormap=(:jet, 0.3))

  ax = CairoMakie.Axis(
    f[2, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_rm], colormap=:grays)
  heatmap!(rm_mask_erode[:, :, z_rm], colormap=(:jet, 0.3))
  f
end

# ╔═╡ af46cfb5-02a1-4738-a7ce-5e52fd81571f
md"""
## Vessels
"""

# ╔═╡ 5b88ce61-57d7-4dff-b8b4-9f89f908d0b8
md"""
### LAD
"""

# ╔═╡ 8e499832-e534-4dd3-88a3-0bc91df3c9cb
lad_arr = load_dcm_array(dcms_lad);

# ╔═╡ 0c2bb318-bcb7-43f5-b445-7806eee4d8a5
begin
  lad_mask = copy(lad_arr)
  replace!(x -> x < -1000 ? 0 : x, lad_mask)
  lad_mask = lad_mask[:, :, end:-1:1]
  lad_mask = lad_mask .!= 0
end;

# ╔═╡ 119b3a5f-213d-4a7c-88a0-904cd7889254
begin
  lad_mask_erode = zeros(size(lad_mask))
  for i in 1:size(lad_mask, 3)
    lad_mask_erode[:, :, i] = erode(lad_mask[:, :, i])
  end
end

# ╔═╡ 8f5a8b87-4306-4ae0-9eb9-c581cd6285bb
@bind z_lad PlutoUI.Slider(axes(lad_mask, 3), show_value=true, default=size(lad_mask, 3) ÷ 15)

# ╔═╡ 36d37e61-af75-4d6a-af48-942e938b62e3
let
  f = Figure(resolution=(2200, 2200))
  ax = CairoMakie.Axis(
    f[1, 1],
    title="Right Myocardium",
    titlesize=40,
  )
  heatmap!(lad_mask[:, :, z_lad], colormap=:grays)

  ax = CairoMakie.Axis(
    f[1, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(lad_mask_erode[:, :, z_lad], colormap=:grays)

  ax = CairoMakie.Axis(
    f[2, 1],
    title="Right Myocardium Mask Overlayed",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_lad], colormap=:grays)
  heatmap!(lad_mask[:, :, z_lad], colormap=(:jet, 0.3))

  ax = CairoMakie.Axis(
    f[2, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_lad], colormap=:grays)
  heatmap!(lad_mask_erode[:, :, z_lad], colormap=(:jet, 0.3))
  f
end

# ╔═╡ ec9bd122-2bc2-4c9d-b48a-6e1c5deabbb0
md"""
### LCX
"""

# ╔═╡ f43d6411-9bb0-4803-998d-a69772698cd1
lcx_arr = load_dcm_array(dcms_lcx);

# ╔═╡ efccdd6f-eaeb-45a5-bd7c-381524379bb5
begin
  lcx_mask = copy(lcx_arr)
  replace!(x -> x < -1000 ? 0 : x, lcx_mask)
  lcx_mask = lcx_mask[:, :, end:-1:1]
  lcx_mask = lcx_mask .!= 0
end;

# ╔═╡ d7fa3230-6191-40fd-90d2-2f9afefb143c
begin
  lcx_mask_erode = zeros(size(lcx_mask))
  for i in 1:size(lcx_mask, 3)
    lcx_mask_erode[:, :, i] = erode(lcx_mask[:, :, i])
  end
end

# ╔═╡ c98bf3b3-ac18-4667-a0af-d6591ad50a5c
@bind z_lcx PlutoUI.Slider(axes(lcx_mask, 3), show_value=true, default=size(lcx_mask, 3) ÷ 15)

# ╔═╡ 20942174-f06e-4704-992a-cd5c17752f35
let
  f = Figure(resolution=(2200, 2200))
  ax = CairoMakie.Axis(
    f[1, 1],
    title="Right Myocardium",
    titlesize=40,
  )
  heatmap!(lcx_mask[:, :, z_lcx], colormap=:grays)

  ax = CairoMakie.Axis(
    f[1, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(lcx_mask_erode[:, :, z_lcx], colormap=:grays)

  ax = CairoMakie.Axis(
    f[2, 1],
    title="Right Myocardium Mask Overlayed",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_lcx], colormap=:grays)
  heatmap!(lcx_mask[:, :, z_lcx], colormap=(:jet, 0.3))

  ax = CairoMakie.Axis(
    f[2, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_lcx], colormap=:grays)
  heatmap!(lcx_mask_erode[:, :, z_lcx], colormap=(:jet, 0.3))
  f
end

# ╔═╡ 86298639-1937-489d-aeca-422c9b6b3e24
md"""
### RCA
"""

# ╔═╡ 2aea052e-b16b-4f71-a125-16dffba93425
rca_arr = load_dcm_array(dcms_rca);

# ╔═╡ 0c625654-a34c-4316-bd63-0c662378886e
begin
  rca_mask = copy(rca_arr)
  replace!(x -> x < -1000 ? 0 : x, rca_mask)
  rca_mask = rca_mask[:, :, end:-1:1]
  rca_mask = rca_mask .!= 0
end;

# ╔═╡ c653ab42-27ec-4a51-b544-7a4e81f09c4b
begin
  rca_mask_erode = zeros(size(rca_mask))
  for i in 1:size(rca_mask, 3)
    rca_mask_erode[:, :, i] = erode(rca_mask[:, :, i])
  end
end

# ╔═╡ c93d11ef-3057-4a89-917a-709c540b9169
@bind z_rca PlutoUI.Slider(axes(rca_mask, 3), show_value=true, default=size(rca_mask, 3) ÷ 15)

# ╔═╡ 5e961ce6-8f80-4c43-bb66-dd0af82d1f3c
let
  f = Figure(resolution=(2200, 2200))
  ax = CairoMakie.Axis(
    f[1, 1],
    title="Right Myocardium",
    titlesize=40,
  )
  heatmap!(rca_mask[:, :, z_rca], colormap=:grays)

  ax = CairoMakie.Axis(
    f[1, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(rca_mask_erode[:, :, z_rca], colormap=:grays)

  ax = CairoMakie.Axis(
    f[2, 1],
    title="Right Myocardium Mask Overlayed",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_rca], colormap=:grays)
  heatmap!(rca_mask[:, :, z_rca], colormap=(:jet, 0.3))

  ax = CairoMakie.Axis(
    f[2, 2],
    title="Right Myocardium Mask Eroded",
    titlesize=40,
  )
  heatmap!(v2_arr[:, :, z_rca], colormap=:grays)
  heatmap!(rca_mask_erode[:, :, z_rca], colormap=(:jet, 0.3))
  f
end

# ╔═╡ 6bf5d4eb-423b-4c1c-870e-fe7850b23137
md"""
## Crop Arrays via Arata Mask
"""

# ╔═╡ c4e52e97-db66-4798-a1e0-0a6d5b66bb9d
bounding_box_indices = find_bounding_box(arata_mask; offset=(20, 20, 5))

# ╔═╡ d75d2a7c-a025-4642-a8bd-fc57577f9aa2
begin
  v2_crop = crop_array(v2_arr, bounding_box_indices...)
  arata_crop = crop_array(arata_mask, bounding_box_indices...)
  lm_crop = crop_array(lm_mask_erode, bounding_box_indices...)
  rm_crop = crop_array(rm_mask_erode, bounding_box_indices...)
end;

# ╔═╡ d4e86abf-fb28-4aa9-aa84-307c974630ad
md"""
# Registration
"""

# ╔═╡ 540ff842-04f9-42a8-9abb-ebb09b19f64b
v2_reg = v2_crop

# ╔═╡ 131cc859-c8fe-43ba-a486-1ccb2d4c1392
# @bind z_reg PlutoUI.Slider(axes(v2_crop, 3), show_value=true, default=182)

# ╔═╡ f2e34124-12df-498a-8632-9f4d34866248
# let
#   f = Figure(resolution=(2200, 1400))
#   ax = CairoMakie.Axis(
#     f[1, 1],
#     title="Unregistered",
#     titlesize=40,
#   )
#   heatmap!(v1_crop[:, :, z_reg])

#   ax = CairoMakie.Axis(
#     f[1, 2],
#     title="Registered",
#     titlesize=40,
#   )
#   heatmap!(v1_crop[:, :, z_reg])
#   f
# end

# ╔═╡ 0fbad88e-7598-4416-ba4f-caab5af09bbb
md"""
# Arterial Input Function (AIF)
"""

# ╔═╡ c966dfc6-3117-4d76-9e12-129e05bbf68a
md"""
## SureStart
"""

# ╔═╡ 84ccac14-41a5-491f-a88d-d364c6d43a2f
md"""
Select slice: $(@bind z1_aif PlutoUI.Slider(axes(ss_arr, 3), show_value = true, default = size(ss_arr, 3)))

Choose x location: $(@bind x1_aif PlutoUI.Slider(axes(ss_arr, 1), show_value = true, default = 239))

Choose y location: $(@bind y1_aif PlutoUI.Slider(axes(ss_arr, 1), show_value = true, default = 274))

Choose radius: $(@bind r1_aif PlutoUI.Slider(1:10, show_value = true, default = 7))

Check box when ready: $(@bind aif1_ready PlutoUI.CheckBox(default = true))
"""

# ╔═╡ 5eb279b5-348f-4c00-bad2-c40f545739be
let
  f = Figure()
  ax = CairoMakie.Axis(
    f[1, 1],
    title="Sure Start AIF",
  )
  heatmap!(ss_arr[:, :, z1_aif], colormap=:grays)

  # Draw circle using parametric equations
  phi = 0:0.01:2π
  circle_x = r1_aif .* cos.(phi) .+ x1_aif
  circle_y = r1_aif .* sin.(phi) .+ y1_aif
  lines!(circle_x, circle_y, label="Aorta Mask (radius $r1_aif)", color=:red, linewidth=1)

  axislegend(ax)

  f
end

# ╔═╡ 7f1b44c5-924b-4541-8fff-e1298f9a9ef0
md"""
## V2 (AIF)
"""

# ╔═╡ 0955548a-62a4-4523-a526-bd123092a03a
md"""
Select slice: $(@bind z2_aif PlutoUI.Slider(axes(v2_reg, 3), show_value = true, default = 59))

Choose x location: $(@bind x2_aif PlutoUI.Slider(axes(v2_reg, 1), show_value = true, default = 55))

Choose y location: $(@bind y2_aif PlutoUI.Slider(axes(v2_reg, 1), show_value = true, default = 76))

Choose radius: $(@bind r2_aif PlutoUI.Slider(1:10, show_value = true, default = 2))

Check box when ready: $(@bind aif2_ready PlutoUI.CheckBox(default = true))
"""

# ╔═╡ e9dad16b-07bc-4b87-be6b-959b078a5ba7
let
  f = Figure()
  ax = CairoMakie.Axis(
    f[1, 1],
    title="V2 AIF",
  )
  heatmap!(v2_reg[:, :, z2_aif], colormap=:grays)

  # Draw circle using parametric equations
  phi = 0:0.01:2π
  circle_x = r2_aif .* cos.(phi) .+ x2_aif
  circle_y = r2_aif .* sin.(phi) .+ y2_aif
  lines!(circle_x, circle_y, label="Femoral Artery Mask (radius $r2_aif)", color=:red, linewidth=0.5)

  axislegend(ax)

  f
end

# ╔═╡ 6864be65-b474-4fa2-84a6-0f8c789e669d
if aif1_ready && aif2_ready
  aif_vec_ss = compute_aif(ss_arr, x1_aif, y1_aif, r1_aif)
  aif_vec_v2 = compute_aif(v2_reg, x2_aif, y2_aif, r2_aif, z2_aif)
  aif_vec_gamma = [aif_vec_ss..., aif_vec_v2]
end

# ╔═╡ 1e21f95a-bc8a-492f-9a56-820dd3b3d066
md"""
# Time Attenuation Curve
"""

# ╔═╡ 0ba3a947-23be-49ca-ac2c-b0d295d096e9
md"""
## Extract SureStart Times
"""

# ╔═╡ 61604f83-e5f3-4aed-ac0b-1c630d7a1d67
if aif1_ready && aif2_ready
  time_vector_ss = scan_time_vector(dcms_ss)
  time_vector_ss_rel = time_vector_ss .- time_vector_ss[1]

  time_vector_v2 = scan_time_vector(dcms_v2)
  time_vector_v2_rel = time_vector_v2 .- time_vector_v2[1]

  delta_time = time_vector_v2[length(time_vector_v2)÷2] - time_vector_ss[end]

  time_vec_gamma = [time_vector_ss_rel..., delta_time + time_vector_ss_rel[end]]
end

# ╔═╡ e385d115-47e4-4a59-a6d0-6ea95455e901
md"""
## Gamma Variate
"""

# ╔═╡ e87721fa-5731-4a3e-bd8d-a17dc8fdeffc
if aif1_ready && aif2_ready
  # Upper and Lower Bounds
  lb = [-1000.0, 1000.0]
  ub = [-1000.0, 1000.0]

  baseline_hu = mean(aif_vec_gamma[1:3])
  p0 = [0.0, baseline_hu]  # Initial guess (0, blood pool offset)

  time_vec_end, aif_vec_end = time_vec_gamma[end], aif_vec_gamma[end]

  fit = gamma_curve_fit(time_vec_gamma, aif_vec_gamma, time_vec_end, aif_vec_end, p0; lower_bounds=lb, upper_bounds=ub)
  opt_params = fit.param
end

# ╔═╡ bec89c24-dea6-490c-8ca1-95a8bae2a1d6
time_vec_gamma, aif_vec_gamma, time_vec_end, aif_vec_end, p0

# ╔═╡ fc43feee-9d9a-4af6-a76a-7dfbb927c0ae
if aif1_ready && aif2_ready
  x_fit = range(start=minimum(time_vec_gamma), stop=maximum(time_vec_gamma), length=500)
  y_fit = gamma(x_fit, opt_params, time_vec_end, aif_vec_end)
  dense_y_fit_adjusted = max.(y_fit .- baseline_hu, 0)

  area_under_curve = trapz(x_fit, dense_y_fit_adjusted)
  times = collect(range(time_vec_gamma[1], stop=time_vec_end, length=round(Int, maximum(time_vec_gamma))))

  input_conc = area_under_curve ./ (time_vec_gamma[19] - times[4])
  if length(aif_vec_gamma) > 2
    input_conc = mean([aif_vec_gamma[end], aif_vec_gamma[end-1]])
  end
end

# ╔═╡ c44b2487-bcd2-43f2-af89-2e3b0e1a54e8
if aif1_ready && aif2_ready
  let
    f = Figure()
    ax = Axis(
      f[1, 1],
      xlabel="Time Point",
      ylabel="Intensity (HU)",
      title="Fitted AIF Curve",
    )

    scatter!(time_vec_gamma, aif_vec_gamma, label="Data Points")
    lines!(x_fit, y_fit, label="Fitted Curve", color=:red)
    scatter!(time_vec_gamma[end-1], aif_vec_gamma[end-1], label="Trigger")
    scatter!(time_vec_gamma[end], aif_vec_gamma[end], label="V2")

    axislegend(ax, position=:lt)

    # Create the AUC plot
    time_temp = range(time_vec_gamma[3], stop=time_vec_gamma[end], length=round(Int, maximum(time_vec_gamma) * 1))
    auc_area = gamma(time_temp, opt_params, time_vec_end, aif_vec_end) .- baseline_hu

    # Create a denser AUC plot
    n_points = 1000  # Number of points for denser interpolation
    time_temp_dense = range(time_temp[1], stop=time_temp[end], length=n_points)
    auc_area_dense = gamma(time_temp_dense, opt_params, time_vec_end, aif_vec_end) .- baseline_hu

    for i ∈ 1:length(auc_area_dense)
      lines!(ax, [time_temp_dense[i], time_temp_dense[i]], [baseline_hu, auc_area_dense[i] + baseline_hu], color=:cyan, linewidth=1, alpha=0.2)
    end

    f
  end
end

# ╔═╡ 5aecb6b9-a813-4cf8-8a7f-2da4a19a052e
md"""
# Whole Organ Perfusion
"""

# ╔═╡ d90057db-c68d-4b70-9247-1098bf129783
md"""
## Prepare Perfusion Details
"""

# ╔═╡ 140c1343-2a6e-4d4f-a3db-0d608d7e885c
if aif1_ready && aif2_ready
  header = dcms_v1[1].meta
  voxel_size = get_voxel_size(header)
  heart_rate = round(1 / (mean(diff(time_vec_gamma)) / 60))
  tissue_rho = 1.053 # tissue density : g/cm^2
  organ_mass = (sum(limb_crop) * tissue_rho * voxel_size[1] * voxel_size[2] * voxel_size[3]) / 1000 # g
  delta_hu = mean(v2_reg[limb_crop]) - mean(v1_crop[limb_crop])
  organ_vol_inplane = voxel_size[1] * voxel_size[2] / 1000
  v1_mass = sum(v1_crop[limb_crop]) * organ_vol_inplane
  v2_mass = sum(v2_reg[limb_crop]) * organ_vol_inplane
  flow = (1 / input_conc) * ((v2_mass - v1_mass) / (delta_time / 60)) # mL/min
  flow_map = (v2_reg - v1_crop) ./ (mean(v2_reg[limb_crop]) - mean(v1_crop[limb_crop])) .* flow # mL/min/g, voxel-by-voxel blood perfusion of organ of interest
  perf_map = flow_map ./ organ_mass
  perf = (flow / organ_mass, std(perf_map[limb_crop]))
end

# ╔═╡ a2aeaa04-3097-4dd0-8bab-5c98b74514b3
if aif1_ready && aif2_ready
  @bind z_flow PlutoUI.Slider(axes(flow_map, 3), show_value=true, default=size(flow_map, 3) ÷ 2)
end

# ╔═╡ f8f3dafc-0fa4-4d11-b301-89d20adf77f3
begin
  limb_crop_dilated = dilate(dilate(dilate(dilate(dilate(limb_crop)))))
  flow_map_nans = zeros(size(flow_map))
  for i in axes(flow_map, 1)
    for j in axes(flow_map, 2)
      for k in axes(flow_map, 3)
        if iszero(limb_crop_dilated[i, j, k])
          flow_map_nans[i, j, k] = NaN
        else
          flow_map_nans[i, j, k] = flow_map[i, j, k]
        end
      end
    end
  end
  flow_map_nans
end;

# ╔═╡ 283c0ee5-0321-4f5d-9792-d593f49cafc1
if aif1_ready && aif2_ready
  let
    f = Figure()
    ax = CairoMakie.Axis(
      f[1, 1],
      title="Flow Map",
    )
    heatmap!(v2_reg[:, :, z_flow], colormap=:grays)
    heatmap!(flow_map_nans[:, :, z_flow], colormap=(:jet, 0.6))

    Colorbar(f[1, 2], limits=(-10, 300), colormap=:jet,
      flipaxis=false)
    f
  end
end

# ╔═╡ 1befeeba-40bb-4310-8441-6609fc82dc21
md"""
## Results
"""

# ╔═╡ c0dcbc56-be6e-47ba-b3e8-9f12ec469e4b
col_names = [
  "perfusion",
  "perfusion_std",
  "perfusion_ref",
  "flow",
  "flow_std",
  "delta_time",
  "mass",
  "delta_hu",
  "heart_rate",
]

# ╔═╡ e79e2a10-78d0-4571-b601-daf9d164b0c9
if aif1_ready && aif2_ready
  col_vals = [
    perf[1],
    perf[2],
    length(perf) == 3 ? perf[3] : missing,
    perf[1] * organ_mass,
    perf[2] * organ_mass,
    delta_time,
    organ_mass,
    delta_hu,
    heart_rate,
  ]
end

# ╔═╡ a861ded4-dbcf-4f06-a1b4-17d8f8ddf214
if aif1_ready && aif2_ready
  df = DataFrame(parameters=col_names, values=col_vals)
end

# ╔═╡ 2c8c49dc-b1f5-4f55-ab8d-d3331d4ec23d
md"""
# Visualiazation
"""

# ╔═╡ 4265f600-d744-49b1-9225-d284b2c947af
md"""
## Show 3D Limb Image
"""

# ╔═╡ b88d27fe-b02d-45fa-9553-c012cafe9e5a
flow_min, flow_max = minimum(flow_map), maximum(flow_map)

# ╔═╡ 04330a9d-d2b5-4b54-8e82-42904bcf3ff1
let
  fig = Figure(resolution=(1200, 1000))

  # control azimuth
  Label(fig[0, 1], "Azimuth", justification=:left, lineheight=1)
  azimuth = GLMakie.Slider(fig[0, 2:3], range=0:0.01:1, startvalue=0.69)
  azimuth_slice = lift(azimuth.value) do a
    a * pi
  end

  # control elevation
  Label(fig[1, 1], "Elevation", justification=:left, lineheight=1)
  elevation = GLMakie.Slider(fig[1, 2:3], range=0:0.01:1, startvalue=0.18)
  elevation_slice = lift(elevation.value) do e
    e * pi
  end

  # control elevation
  Label(fig[2, 1], "Perspectiveness", justification=:left, lineheight=1)
  perspectiveness = GLMakie.Slider(fig[2, 2:3], range=0:0.01:1, startvalue=0.5)
  perspectiveness_slice = lift(perspectiveness.value) do p
    p
  end

  # control colormap
  Label(fig[3, 1], "Color Slider", justification=:left, lineheight=1)
  colormap = Observable(to_colormap(:jet))
  slider = GLMakie.Slider(fig[3, 2:3], range=0:1:8, startvalue=0)
  on(slider.value) do c
    new_colormap = to_colormap(:jet)
    for i in 1:c
      new_colormap[i] = RGBAf(0, 0, 0, 0)
    end
    colormap[] = new_colormap
  end

  # render picture
  ax = GLMakie.Axis3(fig[4, 1:2];
    perspectiveness=perspectiveness_slice,
    azimuth=azimuth_slice,
    elevation=elevation_slice,
    aspect=(1, 1, 1)
  )

  GLMakie.volume!(ax, flow_map_nans;
    colormap=colormap,
    lowclip=:transparent,
    highclip=:transparent,
    nan_color=:transparent,
    transparency=true
  )

  GLMakie.volume!(ax, v2_reg;
    colormap=:greys,
    lowclip=:transparent,
    highclip=:transparent,
    nan_color=:transparent,
    transparency=true
  )

  GLMakie.volume!(ax, v1_crop;
    colormap=:greys,
    lowclip=:transparent,
    highclip=:transparent,
    nan_color=:transparent,
    transparency=true
  )

  Colorbar(fig[4, 3], colormap=:jet, flipaxis=false, colorrange=(flow_min, flow_max))

  fig
  display(fig)
end

# ╔═╡ 97c601e0-7f20-4112-b526-4f1509ce168f
md"""
## Extend to any 3D data
"""

# ╔═╡ 21b31afd-a099-45ef-9bcd-9c61b7b293f9
md"""
**Enter 3D Data File**

Input the name of the file that needs to be 3D shown. Then click submit。

$(@bind visulaztion_file confirm(PlutoUI.TextField(60; default = "/Users/harryxiong24/Code/Lab/perfusion/limb/pred.jld2")))
"""

# ╔═╡ 0dcf9e76-1cd2-403a-b92c-a2679ed5ebf4
let
  @load visulaztion_file ŷ
  min, max = minimum(ŷ), maximum(ŷ)
  f = Figure(resolution=(1200, 1000))

  # control azimuth
  Label(f[0, 1], "Azimuth", justification=:left, lineheight=1)
  azimuth = GLMakie.Slider(f[0, 2:3], range=0:0.01:1, startvalue=0.69)
  azimuth_slice = lift(azimuth.value) do a
    a * pi
  end

  # control elevation
  Label(f[1, 1], "Elevation", justification=:left, lineheight=1)
  elevation = GLMakie.Slider(f[1, 2:3], range=0:0.01:1, startvalue=0.18)
  elevation_slice = lift(elevation.value) do e
    e * pi
  end

  # control elevation
  Label(f[2, 1], "Perspectiveness", justification=:left, lineheight=1)
  perspectiveness = GLMakie.Slider(f[2, 2:3], range=0:0.01:1, startvalue=0.5)
  perspectiveness_slice = lift(perspectiveness.value) do p
    p
  end

  # control colormap
  Label(f[3, 1], "Color Slider", justification=:left, lineheight=1)
  colormap = Observable(to_colormap(:jet))
  slider = GLMakie.Slider(f[3, 2:3], range=0:1:8, startvalue=0)
  on(slider.value) do c
    new_colormap = to_colormap(:jet)
    for i in 1:c
      new_colormap[i] = RGBAf(0, 0, 0, 0)
    end
    colormap[] = new_colormap
  end

  # render picture
  ax = GLMakie.Axis3(f[4, 1:2];
    perspectiveness=perspectiveness_slice,
    azimuth=azimuth_slice,
    elevation=elevation_slice,
    aspect=(1, 1, 1)
  )


  # 向 Axis3 添加 volume 绘图
  GLMakie.volume!(ax, ŷ;
    colormap=colormap,
    lowclip=:transparent,
    highclip=:transparent,
    nan_color=:transparent,
    transparency=true
  )

  Colorbar(f[4, 3], colormap=:jet, colorrange=(min, max), flipaxis=false)

  f
  display(f)
end

# ╔═╡ Cell order:
# ╠═eeba971b-c64e-4195-95ca-5cf2ae5ac590
# ╠═0129d839-fde4-46bf-a2e1-beb79fdd2cab
# ╟─b4252854-a892-48d1-9c67-4b4ac3b74ded
# ╟─6fa28ef7-8e95-43af-9ef1-9fb549590bf7
# ╠═aa13d033-c4a1-455c-8fa2-5cfc5a51b9c2
# ╟─a830eebb-faf8-492b-ac42-2109e5173482
# ╠═cafb7f62-2bd9-493f-9af9-c4d15a554528
# ╠═2efe5c77-d476-4053-ab8b-47a593735690
# ╠═c84f0933-8354-4f89-ab16-032cdebb1101
# ╠═26b7a474-0653-4ff4-9455-df1448623fee
# ╠═185d08b1-a1f7-4bf2-b0c3-84af66dcc415
# ╠═baeb5520-a946-4ce5-9d66-c0407d47cca2
# ╟─82a0af24-d4a9-461b-b054-90fe37fa61e5
# ╠═43c9c836-2492-431a-9664-d4f900279b2e
# ╠═7f54d3c0-945e-4bc3-b2de-f37d93208963
# ╠═0c7580e8-3e49-44bf-b53e-5070be62e722
# ╟─795e6621-0df8-49e5-973a-ada9b37e451f
# ╟─9e791737-a82f-4b07-b6da-fe8d4af1bfe1
# ╠═1aad87c8-82f1-4436-b5db-3b9a9cdfc3cb
# ╟─9d76a68a-d983-41bb-90c8-02853fa5f37f
# ╟─bec6e715-47f9-42b4-9ce7-6df632b8ff54
# ╠═7111f8f3-ba5f-4a38-9145-97190e68a93e
# ╠═a71a2492-bbd8-4660-93d1-de5eb3f8c681
# ╟─0e5ad727-5fd8-4316-abfb-90a6ad93efaa
# ╠═e132b952-0319-4d34-94a1-6cb4882f5eb1
# ╠═17522cca-6b42-4900-9622-6fe8b2174dfc
# ╠═0dd9eb15-d7ec-41de-9b51-871410246076
# ╠═c660c6ae-3632-4529-b062-b9439e3b3709
# ╟─b9f940b3-f4b8-429e-b7e9-fb12e0bf09ac
# ╠═a8d2b330-78d4-463a-93ee-dd293e50df4b
# ╠═8165b2fe-f26b-4594-bcd9-383379fcfe9d
# ╠═d1ab2748-b597-4c3d-8682-2e97a3fba8a0
# ╟─70e6df21-9838-4d17-9765-f5bb78f26633
# ╠═48badd5f-c486-40df-bddb-c8885e629336
# ╠═2c907a9e-efe9-48d4-96e3-866318f657cf
# ╠═e04cf80a-08d5-4ab3-af80-b1cbf4622219
# ╠═1456a54f-da58-43ae-bbbe-55cd2e4c1fb0
# ╠═dcd6620c-2924-49a4-95f8-1067381f4357
# ╟─5289fe3f-93f2-4c93-8e84-f18b2bd7abbd
# ╟─28af079e-9b15-4e68-91f2-f2db66f9d12e
# ╠═25a2b22c-00c3-4064-af40-c82e708249db
# ╠═421ee721-e661-4fa6-86a8-20eb036bb835
# ╟─4f570b2e-4351-4657-ad74-583f5decb238
# ╟─81908744-c519-4442-8b41-95eca9f23cd3
# ╠═63c3c750-ce4b-4838-af34-5a94b87dff16
# ╠═9f8d5935-67ee-4131-8379-b8bb09b99e7d
# ╟─d3ca2ccf-961e-4612-bfa3-c61dbc27dcbb
# ╟─37a39564-c811-4b64-a76d-6071062757b1
# ╠═25541b4e-7c19-44e2-a5a6-27c0b373ea9a
# ╟─60ef5850-638a-4f89-b2be-63d151e2f690
# ╠═9a7b1a51-90a2-472d-8809-0bbdee4afa1f
# ╟─9ed4ce81-bcff-4279-b841-24675dc9f128
# ╠═652ff74c-d8a7-475a-b8cc-3d7ead255226
# ╠═7466ea3c-e2ba-4cff-8ca7-5b155508e3c6
# ╠═9a780ac2-e296-4080-8d72-f06d64a7e65f
# ╠═4afa1c70-3c33-4057-bc5d-f8681a1a1438
# ╠═06e21f58-d074-48ec-895d-1b864f96afde
# ╠═f47640fc-39c3-4649-bfb3-ebffc4ab2503
# ╟─2a01a6c8-e4fe-483a-a304-712683abd901
# ╠═f6965577-c718-4a03-87b6-248818860f7d
# ╟─25a72dd0-7435-4aa9-98b0-d8a6f5ea1eed
# ╠═36be9348-d572-4fa5-86e5-6e529f2d7092
# ╟─a2135aeb-81c2-4ac4-ad62-9409a941c18f
# ╠═fa9fc2d8-52d8-4fd5-9dfa-7cbff1df40d5
# ╠═68435ab7-95d9-4b69-94e7-1941e4788384
# ╠═dffbee2b-f904-4ce0-8e7d-acf49e76018d
# ╠═f8a45540-37d0-4aa9-8f1b-031e48d3956a
# ╠═f0b631f7-9342-4401-ad2b-6e27e4c733df
# ╟─dafc07a2-47a6-46e9-a19a-85f8b6dad425
# ╠═db50e16a-e1c8-4f2d-9189-e62faa318a3d
# ╠═75880cc4-6eaf-45cf-becd-fef59e33dcbf
# ╠═ffd55e13-0f10-43ca-b1ea-d5de4690884c
# ╠═9d612bd9-6b9c-4633-b7be-2a2069fa49b6
# ╠═bdd45ecf-b8ca-42f2-a172-c378e194fddc
# ╟─af46cfb5-02a1-4738-a7ce-5e52fd81571f
# ╠═5b88ce61-57d7-4dff-b8b4-9f89f908d0b8
# ╠═8e499832-e534-4dd3-88a3-0bc91df3c9cb
# ╠═0c2bb318-bcb7-43f5-b445-7806eee4d8a5
# ╠═119b3a5f-213d-4a7c-88a0-904cd7889254
# ╠═8f5a8b87-4306-4ae0-9eb9-c581cd6285bb
# ╠═36d37e61-af75-4d6a-af48-942e938b62e3
# ╟─ec9bd122-2bc2-4c9d-b48a-6e1c5deabbb0
# ╠═f43d6411-9bb0-4803-998d-a69772698cd1
# ╠═efccdd6f-eaeb-45a5-bd7c-381524379bb5
# ╠═d7fa3230-6191-40fd-90d2-2f9afefb143c
# ╠═c98bf3b3-ac18-4667-a0af-d6591ad50a5c
# ╠═20942174-f06e-4704-992a-cd5c17752f35
# ╟─86298639-1937-489d-aeca-422c9b6b3e24
# ╠═2aea052e-b16b-4f71-a125-16dffba93425
# ╠═0c625654-a34c-4316-bd63-0c662378886e
# ╠═c653ab42-27ec-4a51-b544-7a4e81f09c4b
# ╠═c93d11ef-3057-4a89-917a-709c540b9169
# ╠═5e961ce6-8f80-4c43-bb66-dd0af82d1f3c
# ╠═6bf5d4eb-423b-4c1c-870e-fe7850b23137
# ╠═c4e52e97-db66-4798-a1e0-0a6d5b66bb9d
# ╠═d75d2a7c-a025-4642-a8bd-fc57577f9aa2
# ╟─d4e86abf-fb28-4aa9-aa84-307c974630ad
# ╠═540ff842-04f9-42a8-9abb-ebb09b19f64b
# ╠═131cc859-c8fe-43ba-a486-1ccb2d4c1392
# ╠═f2e34124-12df-498a-8632-9f4d34866248
# ╟─0fbad88e-7598-4416-ba4f-caab5af09bbb
# ╠═c966dfc6-3117-4d76-9e12-129e05bbf68a
# ╠═84ccac14-41a5-491f-a88d-d364c6d43a2f
# ╟─5eb279b5-348f-4c00-bad2-c40f545739be
# ╟─7f1b44c5-924b-4541-8fff-e1298f9a9ef0
# ╠═0955548a-62a4-4523-a526-bd123092a03a
# ╠═e9dad16b-07bc-4b87-be6b-959b078a5ba7
# ╠═6864be65-b474-4fa2-84a6-0f8c789e669d
# ╟─1e21f95a-bc8a-492f-9a56-820dd3b3d066
# ╟─0ba3a947-23be-49ca-ac2c-b0d295d096e9
# ╠═61604f83-e5f3-4aed-ac0b-1c630d7a1d67
# ╟─e385d115-47e4-4a59-a6d0-6ea95455e901
# ╠═bec89c24-dea6-490c-8ca1-95a8bae2a1d6
# ╠═e87721fa-5731-4a3e-bd8d-a17dc8fdeffc
# ╠═fc43feee-9d9a-4af6-a76a-7dfbb927c0ae
# ╟─c44b2487-bcd2-43f2-af89-2e3b0e1a54e8
# ╟─5aecb6b9-a813-4cf8-8a7f-2da4a19a052e
# ╟─d90057db-c68d-4b70-9247-1098bf129783
# ╠═140c1343-2a6e-4d4f-a3db-0d608d7e885c
# ╟─a2aeaa04-3097-4dd0-8bab-5c98b74514b3
# ╠═283c0ee5-0321-4f5d-9792-d593f49cafc1
# ╠═f8f3dafc-0fa4-4d11-b301-89d20adf77f3
# ╟─1befeeba-40bb-4310-8441-6609fc82dc21
# ╠═c0dcbc56-be6e-47ba-b3e8-9f12ec469e4b
# ╠═e79e2a10-78d0-4571-b601-daf9d164b0c9
# ╠═a861ded4-dbcf-4f06-a1b4-17d8f8ddf214
# ╟─2c8c49dc-b1f5-4f55-ab8d-d3331d4ec23d
# ╟─4265f600-d744-49b1-9225-d284b2c947af
# ╠═b88d27fe-b02d-45fa-9553-c012cafe9e5a
# ╠═04330a9d-d2b5-4b54-8e82-42904bcf3ff1
# ╟─97c601e0-7f20-4112-b526-4f1509ce168f
# ╟─21b31afd-a099-45ef-9bcd-9c61b7b293f9
# ╠═0dcf9e76-1cd2-403a-b92c-a2679ed5ebf4