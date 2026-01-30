DATASET_CONFIG = {
    "ZKP_contract": {
        "swc_list": ["SWC-101", "SWC-105", "SWC-107", "SWC-110", "SWC-121", "SWC-124", "SWC-128"],
        "techniques": ["mythril", "slither", "smartcheck"]
    },
    "smartbugs_curated": {
        "swc_list": ["SWC-100", "SWC-101", "SWC-102", "SWC-103", "SWC-104", "SWC-105", "SWC-106", "SWC-107", "SWC-108", "SWC-109"],
        "techniques": ["honeybadger", "manticore", "mythril", "osiris", "oyente", "slither", "smartcheck"]
    },
    "SolidiFI-benchmark": {
        "swc_list": ["SWC-101", "SWC-104", "SWC-105", "SWC-107", "SWC-115", "SWC-116", "SWC-136"],
        "techniques": ["manticore", "mythril", "securify", "oyente", "slither", "smartcheck"]
    },
    "DAppSCAN": {
        "swc_list": ["SWC-135", "SWC-108", "SWC-129", "SWC-123", "SWC-100", "SWC-119", "SWC-102", "SWC-103", "SWC-128", "SWC-104", "SWC-126", "SWC-101", "SWC-118", "SWC-105", "SWC-107", "SWC-114", "SWC-120", "SWC-111", "SWC-116", "SWC-113"],
        "techniques": ["mythril", "slither", "smartcheck"]
    }
}
