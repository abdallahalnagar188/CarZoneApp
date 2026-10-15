export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      admin_notifications: {
        Row: {
          body: Json
          created_at: string
          href: string
          id: string
          read: boolean
          title: Json
          type: Database["public"]["Enums"]["admin_notification_type"]
        }
        Insert: {
          body: Json
          created_at?: string
          href?: string
          id?: string
          read?: boolean
          title: Json
          type: Database["public"]["Enums"]["admin_notification_type"]
        }
        Update: {
          body?: Json
          created_at?: string
          href?: string
          id?: string
          read?: boolean
          title?: Json
          type?: Database["public"]["Enums"]["admin_notification_type"]
        }
        Relationships: []
      }
      admin_role_permissions: {
        Row: {
          level: Database["public"]["Enums"]["permission_level"]
          permission_key: string
          role: Database["public"]["Enums"]["admin_role"]
          updated_at: string
        }
        Insert: {
          level?: Database["public"]["Enums"]["permission_level"]
          permission_key: string
          role: Database["public"]["Enums"]["admin_role"]
          updated_at?: string
        }
        Update: {
          level?: Database["public"]["Enums"]["permission_level"]
          permission_key?: string
          role?: Database["public"]["Enums"]["admin_role"]
          updated_at?: string
        }
        Relationships: []
      }
      admin_users: {
        Row: {
          created_at: string
          email: string
          id: string
          last_login_at: string | null
          name: string
          role: Database["public"]["Enums"]["admin_role"]
          status: Database["public"]["Enums"]["admin_status"]
          updated_at: string
          user_id: string | null
        }
        Insert: {
          created_at?: string
          email: string
          id?: string
          last_login_at?: string | null
          name: string
          role: Database["public"]["Enums"]["admin_role"]
          status?: Database["public"]["Enums"]["admin_status"]
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          created_at?: string
          email?: string
          id?: string
          last_login_at?: string | null
          name?: string
          role?: Database["public"]["Enums"]["admin_role"]
          status?: Database["public"]["Enums"]["admin_status"]
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      amenities: {
        Row: {
          active: boolean
          created_at: string
          id: string
          name: Json
          sort_order: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          id: string
          name: Json
          sort_order?: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          created_at?: string
          id?: string
          name?: Json
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      areas: {
        Row: {
          active: boolean
          created_at: string
          id: string
          name: Json
          sort_order: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          id: string
          name: Json
          sort_order?: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          created_at?: string
          id?: string
          name?: Json
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      audit_logs: {
        Row: {
          action: string
          actor_id: string
          actor_name: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          at: string
          branch_id: string | null
          entity: string
          entity_id: string
          id: string
          new_value: string | null
          old_value: string | null
          reason: string | null
        }
        Insert: {
          action: string
          actor_id: string
          actor_name?: string | null
          actor_type: Database["public"]["Enums"]["actor_type"]
          at?: string
          branch_id?: string | null
          entity: string
          entity_id: string
          id?: string
          new_value?: string | null
          old_value?: string | null
          reason?: string | null
        }
        Update: {
          action?: string
          actor_id?: string
          actor_name?: string | null
          actor_type?: Database["public"]["Enums"]["actor_type"]
          at?: string
          branch_id?: string | null
          entity?: string
          entity_id?: string
          id?: string
          new_value?: string | null
          old_value?: string | null
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      branch_amenities: {
        Row: {
          amenity_id: string
          branch_id: string
        }
        Insert: {
          amenity_id: string
          branch_id: string
        }
        Update: {
          amenity_id?: string
          branch_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "branch_amenities_amenity_id_fkey"
            columns: ["amenity_id"]
            isOneToOne: false
            referencedRelation: "amenities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "branch_amenities_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      branch_blocked_slots: {
        Row: {
          branch_id: string
          created_at: string
          created_by: string | null
          ends_at: string
          id: string
          reason: string
          starts_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          created_by?: string | null
          ends_at: string
          id?: string
          reason: string
          starts_at: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          created_by?: string | null
          ends_at?: string
          id?: string
          reason?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "branch_blocked_slots_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "branch_blocked_slots_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      branch_photos: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          position: number
          storage_path: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          position?: number
          storage_path: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          position?: number
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "branch_photos_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      branch_working_hours: {
        Row: {
          branch_id: string
          closed: boolean
          closes_at: string
          opens_at: string
          weekday: number
        }
        Insert: {
          branch_id: string
          closed?: boolean
          closes_at: string
          opens_at: string
          weekday: number
        }
        Update: {
          branch_id?: string
          closed?: boolean
          closes_at?: string
          opens_at?: string
          weekday?: number
        }
        Relationships: [
          {
            foreignKeyName: "branch_working_hours_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      branches: {
        Row: {
          active: boolean
          address: Json
          area_id: string
          auto_confirm: boolean
          business_id: string
          capacity: number
          created_at: string
          featured: boolean
          free_cancel_min: number
          id: string
          lat: number
          lead_time_min: number
          lng: number
          max_advance_days: number
          name: Json
          no_show_grace_min: number
          phone: string
          rating: number
          reminder_min: number
          review_count: number
          slot_interval_min: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          address: Json
          area_id: string
          auto_confirm?: boolean
          business_id: string
          capacity: number
          created_at?: string
          featured?: boolean
          free_cancel_min?: number
          id?: string
          lat: number
          lead_time_min?: number
          lng: number
          max_advance_days?: number
          name: Json
          no_show_grace_min?: number
          phone: string
          rating?: number
          reminder_min?: number
          review_count?: number
          slot_interval_min?: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          address?: Json
          area_id?: string
          auto_confirm?: boolean
          business_id?: string
          capacity?: number
          created_at?: string
          featured?: boolean
          free_cancel_min?: number
          id?: string
          lat?: number
          lead_time_min?: number
          lng?: number
          max_advance_days?: number
          name?: Json
          no_show_grace_min?: number
          phone?: string
          rating?: number
          reminder_min?: number
          review_count?: number
          slot_interval_min?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "branches_area_id_fkey1"
            columns: ["area_id"]
            isOneToOne: false
            referencedRelation: "areas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "branches_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
        ]
      }
      business_settings: {
        Row: {
          business_id: string
          contact_email: string | null
          contact_phone: string | null
          manager_can_edit_services: boolean
          notification_prefs: Json
          updated_at: string
        }
        Insert: {
          business_id: string
          contact_email?: string | null
          contact_phone?: string | null
          manager_can_edit_services?: boolean
          notification_prefs?: Json
          updated_at?: string
        }
        Update: {
          business_id?: string
          contact_email?: string | null
          contact_phone?: string | null
          manager_can_edit_services?: boolean
          notification_prefs?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_settings_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
        ]
      }
      businesses: {
        Row: {
          commission_rate: number | null
          created_at: string
          id: string
          name: Json
          owner_staff_id: string | null
          rating: number
          status: Database["public"]["Enums"]["business_status"]
          status_reason: string | null
          updated_at: string
        }
        Insert: {
          commission_rate?: number | null
          created_at?: string
          id?: string
          name: Json
          owner_staff_id?: string | null
          rating?: number
          status?: Database["public"]["Enums"]["business_status"]
          status_reason?: string | null
          updated_at?: string
        }
        Update: {
          commission_rate?: number | null
          created_at?: string
          id?: string
          name?: Json
          owner_staff_id?: string | null
          rating?: number
          status?: Database["public"]["Enums"]["business_status"]
          status_reason?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "businesses_owner_staff_id_fkey"
            columns: ["owner_staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      complaint_notes: {
        Row: {
          author_admin_id: string | null
          complaint_id: string
          created_at: string
          id: string
          text: string
        }
        Insert: {
          author_admin_id?: string | null
          complaint_id: string
          created_at?: string
          id?: string
          text: string
        }
        Update: {
          author_admin_id?: string | null
          complaint_id?: string
          created_at?: string
          id?: string
          text?: string
        }
        Relationships: [
          {
            foreignKeyName: "complaint_notes_author_admin_id_fkey"
            columns: ["author_admin_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "complaint_notes_complaint_id_fkey"
            columns: ["complaint_id"]
            isOneToOne: false
            referencedRelation: "complaints"
            referencedColumns: ["id"]
          },
        ]
      }
      complaints: {
        Row: {
          assigned_admin_id: string | null
          branch_id: string
          business_id: string
          category: Database["public"]["Enums"]["complaint_category"]
          created_at: string
          customer_id: string
          description: string
          id: string
          order_id: string | null
          resolution: string | null
          status: Database["public"]["Enums"]["complaint_status"]
          ticket: string
          updated_at: string
        }
        Insert: {
          assigned_admin_id?: string | null
          branch_id: string
          business_id: string
          category: Database["public"]["Enums"]["complaint_category"]
          created_at?: string
          customer_id: string
          description: string
          id?: string
          order_id?: string | null
          resolution?: string | null
          status?: Database["public"]["Enums"]["complaint_status"]
          ticket?: string
          updated_at?: string
        }
        Update: {
          assigned_admin_id?: string | null
          branch_id?: string
          business_id?: string
          category?: Database["public"]["Enums"]["complaint_category"]
          created_at?: string
          customer_id?: string
          description?: string
          id?: string
          order_id?: string | null
          resolution?: string | null
          status?: Database["public"]["Enums"]["complaint_status"]
          ticket?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "complaints_assigned_admin_id_fkey"
            columns: ["assigned_admin_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "complaints_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "complaints_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "complaints_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "complaints_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_favorites: {
        Row: {
          branch_id: string
          created_at: string
          customer_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          customer_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          customer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_favorites_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_favorites_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_notifications: {
        Row: {
          body: Json
          created_at: string
          customer_id: string
          href: string
          id: string
          order_id: string | null
          read: boolean
          title: Json
          type: string
        }
        Insert: {
          body: Json
          created_at?: string
          customer_id: string
          href?: string
          id?: string
          order_id?: string | null
          read?: boolean
          title: Json
          type: string
        }
        Update: {
          body?: Json
          created_at?: string
          customer_id?: string
          href?: string
          id?: string
          order_id?: string | null
          read?: boolean
          title?: Json
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_notifications_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_notifications_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      customers: {
        Row: {
          created_at: string
          id: string
          last_active_at: string
          locale: string
          name: string
          phone: string
          status: Database["public"]["Enums"]["account_status"]
          status_reason: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          last_active_at?: string
          locale?: string
          name: string
          phone: string
          status?: Database["public"]["Enums"]["account_status"]
          status_reason?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          last_active_at?: string
          locale?: string
          name?: string
          phone?: string
          status?: Database["public"]["Enums"]["account_status"]
          status_reason?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      day_closings: {
        Row: {
          actual_card: number
          actual_cash: number
          actual_online: number
          branch_id: string
          closed_at: string
          closed_by: string
          date: string
          difference: number | null
          expected_card: number
          expected_cash: number
          expected_online: number
          id: string
          orders_locked: number
          reason: string | null
        }
        Insert: {
          actual_card?: number
          actual_cash?: number
          actual_online?: number
          branch_id: string
          closed_at?: string
          closed_by: string
          date: string
          difference?: number | null
          expected_card?: number
          expected_cash?: number
          expected_online?: number
          id?: string
          orders_locked?: number
          reason?: string | null
        }
        Update: {
          actual_card?: number
          actual_cash?: number
          actual_online?: number
          branch_id?: string
          closed_at?: string
          closed_by?: string
          date?: string
          difference?: number | null
          expected_card?: number
          expected_cash?: number
          expected_online?: number
          id?: string
          orders_locked?: number
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "day_closings_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "day_closings_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_app_health: {
        Row: {
          created_at: string
          id: string
          service_name: string
          status: string
        }
        Insert: {
          created_at?: string
          id?: string
          service_name: string
          status: string
        }
        Update: {
          created_at?: string
          id?: string
          service_name?: string
          status?: string
        }
        Relationships: []
      }
      legacy_areas: {
        Row: {
          created_at: string
          id: string
          lat: number
          lng: number
          name: Json
        }
        Insert: {
          created_at?: string
          id: string
          lat: number
          lng: number
          name: Json
        }
        Update: {
          created_at?: string
          id?: string
          lat?: number
          lng?: number
          name?: Json
        }
        Relationships: []
      }
      legacy_branch_shares: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          platform: string | null
          user_id: string | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          platform?: string | null
          user_id?: string | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          platform?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "branch_shares_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "legacy_branches"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_branches: {
        Row: {
          active: boolean
          address: Json
          amenities: Json
          area_id: string
          business_active: boolean
          business_id: string
          capacity: number
          created_at: string
          featured: boolean
          id: string
          lat: number
          lng: number
          name: Json
          phone: string
          photo_seed: number
          settings: Json
          working_hours: Json
        }
        Insert: {
          active?: boolean
          address: Json
          amenities?: Json
          area_id: string
          business_active?: boolean
          business_id: string
          capacity?: number
          created_at?: string
          featured?: boolean
          id: string
          lat: number
          lng: number
          name: Json
          phone: string
          photo_seed?: number
          settings?: Json
          working_hours?: Json
        }
        Update: {
          active?: boolean
          address?: Json
          amenities?: Json
          area_id?: string
          business_active?: boolean
          business_id?: string
          capacity?: number
          created_at?: string
          featured?: boolean
          id?: string
          lat?: number
          lng?: number
          name?: Json
          phone?: string
          photo_seed?: number
          settings?: Json
          working_hours?: Json
        }
        Relationships: [
          {
            foreignKeyName: "branches_area_id_fkey"
            columns: ["area_id"]
            isOneToOne: false
            referencedRelation: "legacy_areas"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_complaints: {
        Row: {
          created_at: string
          customer_id: string | null
          details: string | null
          id: string
          order_id: string | null
          reason: string | null
          status: string
          ticket_number: string
        }
        Insert: {
          created_at?: string
          customer_id?: string | null
          details?: string | null
          id: string
          order_id?: string | null
          reason?: string | null
          status?: string
          ticket_number: string
        }
        Update: {
          created_at?: string
          customer_id?: string | null
          details?: string | null
          id?: string
          order_id?: string | null
          reason?: string | null
          status?: string
          ticket_number?: string
        }
        Relationships: []
      }
      legacy_customers: {
        Row: {
          access_token: string | null
          created_at: string
          id: string
          name: string
          phone: string
          token_updated_at: string | null
        }
        Insert: {
          access_token?: string | null
          created_at?: string
          id: string
          name: string
          phone: string
          token_updated_at?: string | null
        }
        Update: {
          access_token?: string | null
          created_at?: string
          id?: string
          name?: string
          phone?: string
          token_updated_at?: string | null
        }
        Relationships: []
      }
      legacy_favorites: {
        Row: {
          branch_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "legacy_branches"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_notifications: {
        Row: {
          body: Json
          created_at: string
          id: string
          order_id: string | null
          read: boolean
          title: Json
          type: string
          user_id: string
        }
        Insert: {
          body: Json
          created_at?: string
          id: string
          order_id?: string | null
          read?: boolean
          title: Json
          type: string
          user_id: string
        }
        Update: {
          body?: Json
          created_at?: string
          id?: string
          order_id?: string | null
          read?: boolean
          title?: Json
          type?: string
          user_id?: string
        }
        Relationships: []
      }
      legacy_offers: {
        Row: {
          branch_ids: Json
          created_at: string
          description: Json
          discount_type: string
          discount_value: number
          end_at: string
          featured: boolean
          id: string
          photo_index: number
          platform: boolean
          service_ids: Json
          start_at: string
          status: string
          title: Json
        }
        Insert: {
          branch_ids?: Json
          created_at?: string
          description: Json
          discount_type: string
          discount_value: number
          end_at: string
          featured?: boolean
          id: string
          photo_index?: number
          platform?: boolean
          service_ids?: Json
          start_at: string
          status?: string
          title: Json
        }
        Update: {
          branch_ids?: Json
          created_at?: string
          description?: Json
          discount_type?: string
          discount_value?: number
          end_at?: string
          featured?: boolean
          id?: string
          photo_index?: number
          platform?: boolean
          service_ids?: Json
          start_at?: string
          status?: string
          title?: Json
        }
        Relationships: []
      }
      legacy_orders: {
        Row: {
          branch_id: string
          cancel_reason: string | null
          code: string
          complaint_id: string | null
          created_at: string
          customer_id: string
          discount: number
          duration_min: number
          id: string
          items: Json
          late_cancel: boolean
          note: string | null
          number: string
          offer_id: string | null
          payment_status: string
          scheduled_at: string
          status: string
          subtotal: number
          timeline: Json
          total: number
          vehicle_id: string | null
        }
        Insert: {
          branch_id: string
          cancel_reason?: string | null
          code: string
          complaint_id?: string | null
          created_at?: string
          customer_id: string
          discount?: number
          duration_min: number
          id: string
          items?: Json
          late_cancel?: boolean
          note?: string | null
          number: string
          offer_id?: string | null
          payment_status?: string
          scheduled_at: string
          status?: string
          subtotal: number
          timeline?: Json
          total: number
          vehicle_id?: string | null
        }
        Update: {
          branch_id?: string
          cancel_reason?: string | null
          code?: string
          complaint_id?: string | null
          created_at?: string
          customer_id?: string
          discount?: number
          duration_min?: number
          id?: string
          items?: Json
          late_cancel?: boolean
          note?: string | null
          number?: string
          offer_id?: string | null
          payment_status?: string
          scheduled_at?: string
          status?: string
          subtotal?: number
          timeline?: Json
          total?: number
          vehicle_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "legacy_branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "legacy_customers"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_reviews: {
        Row: {
          branch_id: string
          comment: string
          created_at: string
          customer_name: string
          id: string
          order_id: string | null
          reply: string | null
          service_name: Json
          stars: number
          tags: Json
        }
        Insert: {
          branch_id: string
          comment: string
          created_at?: string
          customer_name: string
          id: string
          order_id?: string | null
          reply?: string | null
          service_name: Json
          stars: number
          tags?: Json
        }
        Update: {
          branch_id?: string
          comment?: string
          created_at?: string
          customer_name?: string
          id?: string
          order_id?: string | null
          reply?: string | null
          service_name?: Json
          stars?: number
          tags?: Json
        }
        Relationships: [
          {
            foreignKeyName: "reviews_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "legacy_branches"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_services: {
        Row: {
          active: boolean
          branch_id: string
          category: string
          created_at: string
          description: Json
          duration_min: number
          id: string
          name: Json
          price: number
          type: string
        }
        Insert: {
          active?: boolean
          branch_id: string
          category: string
          created_at?: string
          description: Json
          duration_min: number
          id: string
          name: Json
          price: number
          type: string
        }
        Update: {
          active?: boolean
          branch_id?: string
          category?: string
          created_at?: string
          description?: Json
          duration_min?: number
          id?: string
          name?: Json
          price?: number
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "services_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "legacy_branches"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_vehicles: {
        Row: {
          color: string
          created_at: string
          customer_id: string
          id: string
          is_default: boolean
          make: string
          model: string
          plate: string
          year: number | null
        }
        Insert: {
          color: string
          created_at?: string
          customer_id: string
          id: string
          is_default?: boolean
          make: string
          model: string
          plate: string
          year?: number | null
        }
        Update: {
          color?: string
          created_at?: string
          customer_id?: string
          id?: string
          is_default?: boolean
          make?: string
          model?: string
          plate?: string
          year?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "legacy_customers"
            referencedColumns: ["id"]
          },
        ]
      }
      offer_branches: {
        Row: {
          branch_id: string
          offer_id: string
        }
        Insert: {
          branch_id: string
          offer_id: string
        }
        Update: {
          branch_id?: string
          offer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "offer_branches_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "offer_branches_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "offers"
            referencedColumns: ["id"]
          },
        ]
      }
      offer_categories: {
        Row: {
          category_id: string
          offer_id: string
        }
        Insert: {
          category_id: string
          offer_id: string
        }
        Update: {
          category_id?: string
          offer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "offer_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "service_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "offer_categories_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "offers"
            referencedColumns: ["id"]
          },
        ]
      }
      offers: {
        Row: {
          business_id: string | null
          created_at: string
          description: Json
          discount_type: Database["public"]["Enums"]["discount_type"]
          discount_value: number
          ends_at: string
          featured: boolean
          id: string
          scope: Database["public"]["Enums"]["offer_scope"]
          starts_at: string
          status: Database["public"]["Enums"]["offer_status"]
          title: Json
          updated_at: string
        }
        Insert: {
          business_id?: string | null
          created_at?: string
          description: Json
          discount_type: Database["public"]["Enums"]["discount_type"]
          discount_value: number
          ends_at: string
          featured?: boolean
          id?: string
          scope: Database["public"]["Enums"]["offer_scope"]
          starts_at: string
          status?: Database["public"]["Enums"]["offer_status"]
          title: Json
          updated_at?: string
        }
        Update: {
          business_id?: string | null
          created_at?: string
          description?: Json
          discount_type?: Database["public"]["Enums"]["discount_type"]
          discount_value?: number
          ends_at?: string
          featured?: boolean
          id?: string
          scope?: Database["public"]["Enums"]["offer_scope"]
          starts_at?: string
          status?: Database["public"]["Enums"]["offer_status"]
          title?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "offers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
        ]
      }
      order_events: {
        Row: {
          actor_id: string
          actor_type: Database["public"]["Enums"]["actor_type"]
          at: string
          id: string
          order_id: string
          status: Database["public"]["Enums"]["order_status"]
        }
        Insert: {
          actor_id: string
          actor_type: Database["public"]["Enums"]["actor_type"]
          at?: string
          id?: string
          order_id: string
          status: Database["public"]["Enums"]["order_status"]
        }
        Update: {
          actor_id?: string
          actor_type?: Database["public"]["Enums"]["actor_type"]
          at?: string
          id?: string
          order_id?: string
          status?: Database["public"]["Enums"]["order_status"]
        }
        Relationships: [
          {
            foreignKeyName: "order_events_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          duration_min: number
          id: string
          name: Json
          order_id: string
          position: number
          price: number
          service_id: string | null
          type: Database["public"]["Enums"]["service_type"]
        }
        Insert: {
          duration_min: number
          id?: string
          name: Json
          order_id: string
          position?: number
          price: number
          service_id?: string | null
          type: Database["public"]["Enums"]["service_type"]
        }
        Update: {
          duration_min?: number
          id?: string
          name?: Json
          order_id?: string
          position?: number
          price?: number
          service_id?: string | null
          type?: Database["public"]["Enums"]["service_type"]
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      order_notes: {
        Row: {
          author_staff_id: string | null
          created_at: string
          id: string
          order_id: string
          text: string
        }
        Insert: {
          author_staff_id?: string | null
          created_at?: string
          id?: string
          order_id: string
          text: string
        }
        Update: {
          author_staff_id?: string | null
          created_at?: string
          id?: string
          order_id?: string
          text?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_notes_author_staff_id_fkey"
            columns: ["author_staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_notes_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          assigned_staff_id: string | null
          branch_id: string
          business_id: string
          cancel_reason: string | null
          cancelled_at: string | null
          cancelled_by_id: string | null
          cancelled_by_type: Database["public"]["Enums"]["actor_type"] | null
          closed_in_day_id: string | null
          code: string
          created_at: string
          customer_id: string | null
          discount_amount: number | null
          discount_pct: number | null
          discount_reason: string | null
          duration_min: number
          flag: string | null
          id: string
          number: string
          offer_id: string | null
          payment_method: Database["public"]["Enums"]["payment_method"] | null
          payment_status: Database["public"]["Enums"]["order_payment_status"]
          plate: string
          plate_normalized: string | null
          scheduled_at: string
          source: Database["public"]["Enums"]["order_source"]
          status: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total: number
          updated_at: string
          vehicle_id: string | null
        }
        Insert: {
          assigned_staff_id?: string | null
          branch_id: string
          business_id: string
          cancel_reason?: string | null
          cancelled_at?: string | null
          cancelled_by_id?: string | null
          cancelled_by_type?: Database["public"]["Enums"]["actor_type"] | null
          closed_in_day_id?: string | null
          code?: string
          created_at?: string
          customer_id?: string | null
          discount_amount?: number | null
          discount_pct?: number | null
          discount_reason?: string | null
          duration_min: number
          flag?: string | null
          id?: string
          number: string
          offer_id?: string | null
          payment_method?: Database["public"]["Enums"]["payment_method"] | null
          payment_status?: Database["public"]["Enums"]["order_payment_status"]
          plate: string
          plate_normalized?: string | null
          scheduled_at: string
          source: Database["public"]["Enums"]["order_source"]
          status?: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total: number
          updated_at?: string
          vehicle_id?: string | null
        }
        Update: {
          assigned_staff_id?: string | null
          branch_id?: string
          business_id?: string
          cancel_reason?: string | null
          cancelled_at?: string | null
          cancelled_by_id?: string | null
          cancelled_by_type?: Database["public"]["Enums"]["actor_type"] | null
          closed_in_day_id?: string | null
          code?: string
          created_at?: string
          customer_id?: string | null
          discount_amount?: number | null
          discount_pct?: number | null
          discount_reason?: string | null
          duration_min?: number
          flag?: string | null
          id?: string
          number?: string
          offer_id?: string | null
          payment_method?: Database["public"]["Enums"]["payment_method"] | null
          payment_status?: Database["public"]["Enums"]["order_payment_status"]
          plate?: string
          plate_normalized?: string | null
          scheduled_at?: string
          source?: Database["public"]["Enums"]["order_source"]
          status?: Database["public"]["Enums"]["order_status"]
          subtotal?: number
          total?: number
          updated_at?: string
          vehicle_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "orders_assigned_staff_id_fkey"
            columns: ["assigned_staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_branch_id_fkey1"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_closed_in_day_fkey"
            columns: ["closed_in_day_id"]
            isOneToOne: false
            referencedRelation: "day_closings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_customer_id_fkey1"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "offers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          collected_at: string
          collected_by: string | null
          created_at: string
          id: string
          method: Database["public"]["Enums"]["payment_method"]
          order_id: string
          status: Database["public"]["Enums"]["payment_status"]
        }
        Insert: {
          amount: number
          collected_at?: string
          collected_by?: string | null
          created_at?: string
          id?: string
          method: Database["public"]["Enums"]["payment_method"]
          order_id: string
          status?: Database["public"]["Enums"]["payment_status"]
        }
        Update: {
          amount?: number
          collected_at?: string
          collected_by?: string | null
          created_at?: string
          id?: string
          method?: Database["public"]["Enums"]["payment_method"]
          order_id?: string
          status?: Database["public"]["Enums"]["payment_status"]
        }
        Relationships: [
          {
            foreignKeyName: "payments_collected_by_fkey"
            columns: ["collected_by"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      payouts: {
        Row: {
          amount_due: number
          amount_paid: number
          business_id: string
          created_at: string
          id: string
          paid_at: string | null
          period_end: string
          period_start: string
          reference: string | null
          status: Database["public"]["Enums"]["payout_status"]
          updated_at: string
        }
        Insert: {
          amount_due: number
          amount_paid?: number
          business_id: string
          created_at?: string
          id?: string
          paid_at?: string | null
          period_end: string
          period_start: string
          reference?: string | null
          status?: Database["public"]["Enums"]["payout_status"]
          updated_at?: string
        }
        Update: {
          amount_due?: number
          amount_paid?: number
          business_id?: string
          created_at?: string
          id?: string
          paid_at?: string | null
          period_end?: string
          period_start?: string
          reference?: string | null
          status?: Database["public"]["Enums"]["payout_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payouts_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_settings: {
        Row: {
          key: string
          updated_at: string
          updated_by: string | null
          value: Json
        }
        Insert: {
          key: string
          updated_at?: string
          updated_by?: string | null
          value: Json
        }
        Update: {
          key?: string
          updated_at?: string
          updated_by?: string | null
          value?: Json
        }
        Relationships: [
          {
            foreignKeyName: "platform_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      push_devices: {
        Row: {
          app: string
          app_version: string | null
          created_at: string
          id: string
          last_seen_at: string
          platform: string
          token: string
          user_id: string
        }
        Insert: {
          app: string
          app_version?: string | null
          created_at?: string
          id?: string
          last_seen_at?: string
          platform: string
          token: string
          user_id: string
        }
        Update: {
          app?: string
          app_version?: string | null
          created_at?: string
          id?: string
          last_seen_at?: string
          platform?: string
          token?: string
          user_id?: string
        }
        Relationships: []
      }
      reviews: {
        Row: {
          branch_id: string
          business_id: string
          comment: Json
          created_at: string
          customer_id: string
          hidden_reason: string | null
          id: string
          order_id: string
          reply: string | null
          reply_at: string | null
          report_reason: string | null
          reported_by_wash: boolean
          service_id: string | null
          stars: number
          status: Database["public"]["Enums"]["review_status"]
          tags: string[]
          updated_at: string
        }
        Insert: {
          branch_id: string
          business_id: string
          comment: Json
          created_at?: string
          customer_id: string
          hidden_reason?: string | null
          id?: string
          order_id: string
          reply?: string | null
          reply_at?: string | null
          report_reason?: string | null
          reported_by_wash?: boolean
          service_id?: string | null
          stars: number
          status?: Database["public"]["Enums"]["review_status"]
          tags?: string[]
          updated_at?: string
        }
        Update: {
          branch_id?: string
          business_id?: string
          comment?: Json
          created_at?: string
          customer_id?: string
          hidden_reason?: string | null
          id?: string
          order_id?: string
          reply?: string | null
          reply_at?: string | null
          report_reason?: string | null
          reported_by_wash?: boolean
          service_id?: string | null
          stars?: number
          status?: Database["public"]["Enums"]["review_status"]
          tags?: string[]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reviews_branch_id_fkey1"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      service_categories: {
        Row: {
          active: boolean
          created_at: string
          id: string
          name: Json
          sort_order: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          id: string
          name: Json
          sort_order?: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          created_at?: string
          id?: string
          name?: Json
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      services: {
        Row: {
          active: boolean
          branch_id: string
          category_id: string
          created_at: string
          description: Json | null
          duration_min: number
          id: string
          name: Json
          price: number
          type: Database["public"]["Enums"]["service_type"]
          updated_at: string
        }
        Insert: {
          active?: boolean
          branch_id: string
          category_id: string
          created_at?: string
          description?: Json | null
          duration_min: number
          id?: string
          name: Json
          price: number
          type: Database["public"]["Enums"]["service_type"]
          updated_at?: string
        }
        Update: {
          active?: boolean
          branch_id?: string
          category_id?: string
          created_at?: string
          description?: Json | null
          duration_min?: number
          id?: string
          name?: Json
          price?: number
          type?: Database["public"]["Enums"]["service_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "services_branch_id_fkey1"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "service_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      staff: {
        Row: {
          branch_id: string | null
          business_id: string
          created_at: string
          id: string
          joined_at: string
          max_discount_pct: number
          name: string
          permissions: Json
          phone: string
          pin_hash: string | null
          role: Database["public"]["Enums"]["staff_role"]
          status: Database["public"]["Enums"]["account_status"]
          updated_at: string
          user_id: string | null
        }
        Insert: {
          branch_id?: string | null
          business_id: string
          created_at?: string
          id?: string
          joined_at?: string
          max_discount_pct?: number
          name: string
          permissions: Json
          phone: string
          pin_hash?: string | null
          role: Database["public"]["Enums"]["staff_role"]
          status?: Database["public"]["Enums"]["account_status"]
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          branch_id?: string | null
          business_id?: string
          created_at?: string
          id?: string
          joined_at?: string
          max_discount_pct?: number
          name?: string
          permissions?: Json
          phone?: string
          pin_hash?: string | null
          role?: Database["public"]["Enums"]["staff_role"]
          status?: Database["public"]["Enums"]["account_status"]
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "staff_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_shift_patterns: {
        Row: {
          created_at: string
          days: number[]
          ends_at: string
          id: string
          staff_id: string
          starts_at: string
        }
        Insert: {
          created_at?: string
          days: number[]
          ends_at: string
          id?: string
          staff_id: string
          starts_at: string
        }
        Update: {
          created_at?: string
          days?: number[]
          ends_at?: string
          id?: string
          staff_id?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_shift_patterns_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_shifts: {
        Row: {
          actual_cash: number | null
          actual_end: string | null
          actual_start: string | null
          branch_id: string
          card_payments: number
          cash_payments: number
          created_at: string
          difference: number | null
          difference_reason: Json | null
          expected_cash: number
          id: string
          opening_cash: number
          orders_completed: number
          review_note: string | null
          review_status: Database["public"]["Enums"]["shift_review_status"]
          reviewed_by: string | null
          scheduled_end: string
          scheduled_start: string
          staff_id: string
          updated_at: string
        }
        Insert: {
          actual_cash?: number | null
          actual_end?: string | null
          actual_start?: string | null
          branch_id: string
          card_payments?: number
          cash_payments?: number
          created_at?: string
          difference?: number | null
          difference_reason?: Json | null
          expected_cash?: number
          id?: string
          opening_cash?: number
          orders_completed?: number
          review_note?: string | null
          review_status?: Database["public"]["Enums"]["shift_review_status"]
          reviewed_by?: string | null
          scheduled_end: string
          scheduled_start: string
          staff_id: string
          updated_at?: string
        }
        Update: {
          actual_cash?: number | null
          actual_end?: string | null
          actual_start?: string | null
          branch_id?: string
          card_payments?: number
          cash_payments?: number
          created_at?: string
          difference?: number | null
          difference_reason?: Json | null
          expected_cash?: number
          id?: string
          opening_cash?: number
          orders_completed?: number
          review_note?: string | null
          review_status?: Database["public"]["Enums"]["shift_review_status"]
          reviewed_by?: string | null
          scheduled_end?: string
          scheduled_start?: string
          staff_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_shifts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_shifts_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_shifts_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      transactions: {
        Row: {
          business_id: string
          commission: number
          commission_rate: number
          created_at: string
          date: string
          flag: string | null
          gross: number
          id: string
          net_to_wash: number
          order_id: string
          review_note: string | null
          status: Database["public"]["Enums"]["transaction_status"]
          updated_at: string
        }
        Insert: {
          business_id: string
          commission: number
          commission_rate: number
          created_at?: string
          date: string
          flag?: string | null
          gross: number
          id?: string
          net_to_wash: number
          order_id: string
          review_note?: string | null
          status?: Database["public"]["Enums"]["transaction_status"]
          updated_at?: string
        }
        Update: {
          business_id?: string
          commission?: number
          commission_rate?: number
          created_at?: string
          date?: string
          flag?: string | null
          gross?: number
          id?: string
          net_to_wash?: number
          order_id?: string
          review_note?: string | null
          status?: Database["public"]["Enums"]["transaction_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "transactions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicles: {
        Row: {
          color: string
          created_at: string
          customer_id: string
          id: string
          is_default: boolean
          make: string
          model: string
          plate: string
          plate_normalized: string | null
          updated_at: string
          year: number | null
        }
        Insert: {
          color: string
          created_at?: string
          customer_id: string
          id?: string
          is_default?: boolean
          make: string
          model: string
          plate: string
          plate_normalized?: string | null
          updated_at?: string
          year?: number | null
        }
        Update: {
          color?: string
          created_at?: string
          customer_id?: string
          id?: string
          is_default?: boolean
          make?: string
          model?: string
          plate?: string
          plate_normalized?: string | null
          updated_at?: string
          year?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_customer_id_fkey1"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
        ]
      }
      vendor_notifications: {
        Row: {
          body: Json
          branch_id: string | null
          business_id: string
          created_at: string
          href: string
          id: string
          read: boolean
          staff_id: string | null
          title: Json
          type: Database["public"]["Enums"]["vendor_notification_type"]
        }
        Insert: {
          body: Json
          branch_id?: string | null
          business_id: string
          created_at?: string
          href?: string
          id?: string
          read?: boolean
          staff_id?: string | null
          title: Json
          type: Database["public"]["Enums"]["vendor_notification_type"]
        }
        Update: {
          body?: Json
          branch_id?: string | null
          business_id?: string
          created_at?: string
          href?: string
          id?: string
          read?: boolean
          staff_id?: string | null
          title?: Json
          type?: Database["public"]["Enums"]["vendor_notification_type"]
        }
        Relationships: [
          {
            foreignKeyName: "vendor_notifications_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_notifications_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendor_notifications_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff"
            referencedColumns: ["id"]
          },
        ]
      }
      wash_applications: {
        Row: {
          address: string
          area_id: string
          business_id: string | null
          business_name: string
          capacity: number
          documents: string[]
          email: string
          id: string
          lat: number
          lng: number
          owner_name: string
          phone: string
          review_note: string | null
          reviewed_at: string | null
          services: Json
          status: Database["public"]["Enums"]["application_status"]
          submitted_at: string
          updated_at: string
          working_hours: Json
        }
        Insert: {
          address: string
          area_id: string
          business_id?: string | null
          business_name: string
          capacity: number
          documents?: string[]
          email: string
          id?: string
          lat: number
          lng: number
          owner_name: string
          phone: string
          review_note?: string | null
          reviewed_at?: string | null
          services: Json
          status?: Database["public"]["Enums"]["application_status"]
          submitted_at?: string
          updated_at?: string
          working_hours: Json
        }
        Update: {
          address?: string
          area_id?: string
          business_id?: string | null
          business_name?: string
          capacity?: number
          documents?: string[]
          email?: string
          id?: string
          lat?: number
          lng?: number
          owner_name?: string
          phone?: string
          review_note?: string | null
          reviewed_at?: string | null
          services?: Json
          status?: Database["public"]["Enums"]["application_status"]
          submitted_at?: string
          updated_at?: string
          working_hours?: Json
        }
        Relationships: [
          {
            foreignKeyName: "wash_applications_area_id_fkey"
            columns: ["area_id"]
            isOneToOne: false
            referencedRelation: "areas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wash_applications_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      gen_check_in_code: { Args: never; Returns: string }
      gen_id: { Args: { prefix: string }; Returns: string }
      is_localized: { Args: { value: Json }; Returns: boolean }
      next_complaint_ticket: { Args: never; Returns: string }
      next_order_number: {
        Args: { src: Database["public"]["Enums"]["order_source"] }
        Returns: string
      }
      normalize_plate: { Args: { plate: string }; Returns: string }
    }
    Enums: {
      account_status: "active" | "suspended"
      actor_type: "customer" | "staff" | "admin" | "system"
      admin_notification_type:
        | "application"
        | "complaint"
        | "critical_review"
        | "payment_issue"
        | "unusual_activity"
        | "system"
        | "finance_flag"
      admin_role: "super" | "operations" | "finance" | "support"
      admin_status: "active" | "inactive"
      application_status: "pending" | "needs_changes" | "approved" | "rejected"
      business_status:
        | "pending"
        | "approved"
        | "active"
        | "suspended"
        | "rejected"
      complaint_category:
        | "quality"
        | "pricing"
        | "behavior"
        | "booking"
        | "refund"
        | "other"
      complaint_status: "open" | "in_review" | "waiting" | "resolved" | "closed"
      discount_type: "percent" | "fixed"
      offer_scope: "platform" | "wash"
      offer_status: "draft" | "scheduled" | "active" | "expired" | "disabled"
      order_payment_status: "pending" | "paid" | "refunded"
      order_source: "app" | "walk_in" | "phone"
      order_status:
        | "pending"
        | "confirmed"
        | "waiting"
        | "in_service"
        | "completed"
        | "cancelled"
        | "no_show"
      payment_method: "cash" | "card" | "online"
      payment_status: "paid" | "refunded"
      payout_status: "due" | "paid"
      permission_level: "none" | "view" | "manage"
      review_status: "visible" | "hidden"
      service_type: "primary" | "addon"
      shift_review_status: "open" | "submitted" | "reviewed" | "flagged"
      staff_role: "owner" | "manager" | "employee"
      transaction_status: "pending" | "paid" | "refunded" | "settled"
      vendor_notification_type:
        | "new_booking"
        | "booking_cancelled"
        | "cash_difference"
        | "high_cancellation"
        | "branch_issue"
        | "daily_summary"
        | "review"
        | "platform"
        | "payout"
        | "shift"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      account_status: ["active", "suspended"],
      actor_type: ["customer", "staff", "admin", "system"],
      admin_notification_type: [
        "application",
        "complaint",
        "critical_review",
        "payment_issue",
        "unusual_activity",
        "system",
        "finance_flag",
      ],
      admin_role: ["super", "operations", "finance", "support"],
      admin_status: ["active", "inactive"],
      application_status: ["pending", "needs_changes", "approved", "rejected"],
      business_status: [
        "pending",
        "approved",
        "active",
        "suspended",
        "rejected",
      ],
      complaint_category: [
        "quality",
        "pricing",
        "behavior",
        "booking",
        "refund",
        "other",
      ],
      complaint_status: ["open", "in_review", "waiting", "resolved", "closed"],
      discount_type: ["percent", "fixed"],
      offer_scope: ["platform", "wash"],
      offer_status: ["draft", "scheduled", "active", "expired", "disabled"],
      order_payment_status: ["pending", "paid", "refunded"],
      order_source: ["app", "walk_in", "phone"],
      order_status: [
        "pending",
        "confirmed",
        "waiting",
        "in_service",
        "completed",
        "cancelled",
        "no_show",
      ],
      payment_method: ["cash", "card", "online"],
      payment_status: ["paid", "refunded"],
      payout_status: ["due", "paid"],
      permission_level: ["none", "view", "manage"],
      review_status: ["visible", "hidden"],
      service_type: ["primary", "addon"],
      shift_review_status: ["open", "submitted", "reviewed", "flagged"],
      staff_role: ["owner", "manager", "employee"],
      transaction_status: ["pending", "paid", "refunded", "settled"],
      vendor_notification_type: [
        "new_booking",
        "booking_cancelled",
        "cash_difference",
        "high_cancellation",
        "branch_issue",
        "daily_summary",
        "review",
        "platform",
        "payout",
        "shift",
      ],
    },
  },
} as const
