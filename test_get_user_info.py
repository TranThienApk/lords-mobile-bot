#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lords Mobile - Test Get User Info
Script test cơ bản để lấy thông tin người chơi từ Lords Mobile API
"""

import requests
import hashlib
import time
import json
from datetime import datetime

# ==================== CẤU HÌNH ====================
CONFIG = {
    "region": "ap-seoul",  # ap-seoul (Asia), eu-frankfurt (EU), na-newyork (NA)
    "kingdom_id": 1234,     # ID vương quốc của bạn
    "secret_key": "lm2025iggtrackx9",  # Secret key từ reverse engineering
    "device_id": "android_test_001",
    "token": ""  # Sẽ được lấy từ login
}

# Base URL
API_BASE = f"https://lmapi-{CONFIG['region']}.lordsmobile.igg.com/api"

# ==================== HELPER FUNCTIONS ====================
def gen_sign(params, secret_key):
    """
    Tạo chữ ký MD5 cho request
    Format: MD5(sorted_params & SECRET_KEY)
    """
    # Sắp xếp params theo alphabet
    sorted_params = "&".join(f"{k}={v}" for k, v in sorted(params.items()))
    # Thêm secret key và hash MD5
    sign_string = sorted_params + secret_key
    return hashlib.md5(sign_string.encode()).hexdigest().lower()

def make_request(endpoint, params, token=None):
    """
    Gửi request đến Lords Mobile API
    """
    # Tạo body
    body = {
        "params": params,
        "ts": int(time.time()),
        "sign": gen_sign(params, CONFIG["secret_key"])
    }
    
    # Headers
    headers = {
        "Device-ID": CONFIG["device_id"],
        "Content-Type": "application/json",
        "User-Agent": "UnityPlayer/2022.3.40f1 (Android)"
    }
    
    # Thêm token nếu có
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    # Gửi request
    url = f"{API_BASE}/{endpoint}"
    
    print(f"\n{'='*60}")
    print(f"📡 REQUEST: {endpoint}")
    print(f"{'='*60}")
    print(f"URL: {url}")
    print(f"Body: {json.dumps(body, indent=2)}")
    print(f"Headers: {json.dumps(headers, indent=2)}")
    
    try:
        response = requests.post(url, json=body, headers=headers, timeout=10)
        
        print(f"\n{'='*60}")
        print(f"📥 RESPONSE: {response.status_code}")
        print(f"{'='*60}")
        
        if response.status_code == 200:
            data = response.json()
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return data
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Exception: {str(e)}")
        return None


# ==================== API FUNCTIONS ====================
def login_by_udid(udid, device_type="android", platform="igg"):
    """
    Login và lấy Bearer token
    """
    params = {
        "udid": udid,
        "device_type": device_type,
        "platform": platform
    }
    
    response = make_request("login_by_udid", params)
    
    if response and "response_data" in response:
        token = response["response_data"].get("token")
        if token:
            CONFIG["token"] = token
            print(f"\n✅ Login thành công!")
            print(f"🔑 Token: {token[:50]}...")
            return token
    
    print(f"\n❌ Login thất bại!")
    return None


def get_user_info(user_id=None, castle_id=None):
    """
    Lấy thông tin người chơi
    Params: user_id HOẶC castle_id
    """
    if not CONFIG["token"]:
        print("❌ Chưa có token! Hãy login trước.")
        return None
    
    params = {}
    if user_id:
        params["user_id"] = user_id
    elif castle_id:
        params["castle_id"] = castle_id
    else:
        print("❌ Cần user_id hoặc castle_id!")
        return None
    
    response = make_request("get_user_info", params, CONFIG["token"])
    
    if response and "response_data" in response:
        user = response["response_data"].get("user", {})
        
        print(f"\n{'='*60}")
        print(f"👤 THÔNG TIN NGƯỜI CHƠI")
        print(f"{'='*60}")
        print(f"🏰 Castle ID: {user.get('castle_id', 'N/A')}")
        print(f"👑 Player Name: {user.get('name', 'N/A')}")
        print(f"💪 Might: {user.get('might', 0):,}")
        print(f"🎖️  VIP Level: {user.get('vip_level', 0)}")
        print(f"⚔️  Leader Level: {user.get('leader_level', 0)}")
        print(f"🏆 Guild: {user.get('guild_name', 'No Guild')}")
        
        # Resources
        resources = user.get('resources', {})
        if resources:
            print(f"\n💎 TÀI NGUYÊN:")
            print(f"   🌾 Food: {resources.get('food', 0):,}")
            print(f"   ⛏️  Ore: {resources.get('ore', 0):,}")
            print(f"   🌲 Timber: {resources.get('timber', 0):,}")
            print(f"   🪨 Stone: {resources.get('stone', 0):,}")
            print(f"   💰 Gold: {resources.get('gold', 0):,}")
            print(f"   💎 Gems: {resources.get('gems', 0):,}")
        
        # Troops (if available)
        troops = user.get('troops', {})
        if troops:
            print(f"\n⚔️  QUÂN ĐỘI:")
            for tier, count in troops.items():
                print(f"   {tier}: {count:,}")
        
        return user
    
    return None


def get_castle_detail(x, y, kingdom_id=None):
    """
    Lấy chi tiết lâu đài theo tọa độ
    """
    if not CONFIG["token"]:
        print("❌ Chưa có token! Hãy login trước.")
        return None
    
    kid = kingdom_id or CONFIG["kingdom_id"]
    
    params = {
        "kingdom_id": kid,
        "x": x,
        "y": y
    }
    
    response = make_request("get_castle_detail", params, CONFIG["token"]) 
    
    if response and "response_data" in response:
        castle = response["response_data"].get("castle", {})
        
        print(f"\n{'='*60}")
        print(f"🏰 CHI TIẾT LÂU ĐÀI ({x}, {y})")
        print(f"{'='*60}")
        print(f"👤 Owner: {castle.get('owner_name', 'N/A')}")
        print(f"💪 Might: {castle.get('might', 0):,}")
        print(f"🏆 Guild: {castle.get('guild_name', 'No Guild')}")
        print(f"🛡️  Shield: {castle.get('shield_remaining', 0)}s")
        print(f"😡 Fury: {castle.get('fury_time', 0)}s")
        print(f"🎯 Rallies: {len(castle.get('incoming_rallies', []))}")
        
        return castle
    
    return None


def refresh_token(old_token):
    """
    Refresh token (24h expire)
    """
    params = {
        "old_token": old_token
    }
    
    response = make_request("refresh_token", params)
    
    if response and "response_data" in response:
        new_token = response["response_data"].get("new_token")
        if new_token:
            CONFIG["token"] = new_token
            print(f"\n✅ Token refreshed!")
            return new_token
    
    return None


# ==================== MAIN TEST ====================
def main():
    """
    Main test function
    """
    print(f"""
╔════════════════════════════════════════════════════════════╗
║     LORDS MOBILE - TEST GET USER INFO                      ║
║     Reverse Engineered API Test Script                     ║
╚════════════════════════════════════════════════════════════╝
    """)
    
    print("📝 Hướng dẫn sử dụng:")
    print("1. Bạn cần có UDID của thiết bị (hoặc fake UDID)")
    print("2. Cần có SECRET_KEY từ reverse engineering")
    print("3. Script sẽ test login và lấy thông tin user\n")
    
    # Test 1: Login
    print("\n" + "="*60)
    print("TEST 1: LOGIN BY UDID")
    print("="*60)
    
    # Thay đổi UDID của bạn ở đây
    test_udid = "test_device_12345678"
    
    print(f"⚠️  UDID test: {test_udid}")
    print("⚠️  Đây là test với fake UDID - sẽ FAIL nếu không đúng!")
    
    choice = input("\n❓ Bạn có UDID thật không? (y/n): ").lower()
    
    if choice == 'y':
        udid = input("Nhập UDID của bạn: ")
    else:
        udid = test_udid
        print("⚠️  Sử dụng fake UDID - Login sẽ thất bại (demo only)")
    
    token = login_by_udid(udid)
    
    if not token:
        print("\n❌ Login thất bại!")
        print("💡 Lý do có thể:")
        print("   1. UDID không đúng")
        print("   2. SECRET_KEY không đúng")
        print("   3. Region không đúng")
        print("   4. API endpoint đã thay đổi")
        print("\n⚠️  Script sẽ tiếp tục với DEMO mode (không có token thật)")
    
    # Test 2: Get User Info
    print("\n" + "="*60)
    print("TEST 2: GET USER INFO")
    print("="*60)
    
    if token:
        user_id = input("Nhập User ID (hoặc Enter để skip): ")
        if user_id:
            get_user_info(user_id=int(user_id))
    else:
        print("⚠️  Skipped - Không có token")
    
    # Test 3: Get Castle Detail
    print("\n" + "="*60)
    print("TEST 3: GET CASTLE DETAIL")
    print("="*60)
    
    if token:
        x = input("Nhập tọa độ X (hoặc Enter để skip): ")
        y = input("Nhập tọa độ Y: ") if x else ""
        
        if x and y:
            get_castle_detail(int(x), int(y))
    else:
        print("⚠️  Skipped - Không có token")
    
    # Summary
    print(f"\n{'='*60}")
    print("📊 KẾT QUẢ TEST")
    print(f"{'='*60}")
    print(f"Region: {CONFIG['region']}")
    print(f"API Base: {API_BASE}")
    print(f"Token: {'✅ Có' if CONFIG['token'] else '❌ Không'}")
    print(f"\n⚠️  LƯU Ý:")
    print("- API này từ reverse engineering - không chính thức")
    print("- Sử dụng có thể bị ban account")
    print("- Chỉ dùng cho mục đích học tập")


if __name__ == "__main__":
    main()